//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::fixtures::UpdateClientAndMembershipCmd,
    helpers::light_block::LightBlockExt,
    programs::{
        MembershipProgram, SP1Program, UpdateClientAndMembershipProgram, UpdateClientProgram,
    },
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRpcExt,
};
use alloy_sol_types::SolValue;
use ibc_core_commitment_types::merkle::MerkleProof;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{Env, UcAndMembershipOutput};
use sp1_ics07_tendermint_utils::convert_tm_to_ics_merkle_proof;
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::{Client, HttpClient};

/// The fixture data to be used in [`UpdateClientProgram`] tests.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07UpdateClientAndMembershipFixture {
    /// The encoded trusted client state.
    trusted_client_state: String,
    /// The encoded trusted consensus state.
    trusted_consensus_state: String,
    /// The encoded target consensus state.
    target_consensus_state: String,
    /// Target height.
    target_height: u32,
    /// The encoded key for the [`UpdateClientProgram`].
    update_client_vkey: String,
    /// The encoded key for the [`MembershipProgram`].
    membership_vkey: String,
    /// The encoded key for the [`UpdateClientAndMembershipProgram`].
    uc_and_membership_vkey: String,
    /// The encoded public values.
    public_values: String,
    /// The encoded proof.
    proof: String,
    /// Hex-encoded `KVPair` value.
    kv_pairs: String,
}

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: UpdateClientAndMembershipCmd) -> anyhow::Result<()> {
    assert!(
        args.trusted_block < args.target_block,
        "The target block must be greater than the trusted block"
    );

    let tm_rpc_client = HttpClient::from_env();
    let uc_mem_prover = SP1ICS07TendermintProver::<UpdateClientAndMembershipProgram>::default();

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.trusted_block))
        .await?;
    let target_light_block = tm_rpc_client
        .get_light_block(Some(args.target_block))
        .await?;

    let unbonding_period = tm_rpc_client
        .sdk_staking_params()
        .await?
        .unbonding_time
        .ok_or_else(|| anyhow::anyhow!("No unbonding time found"))?
        .seconds
        .try_into()?;

    let trusted_client_state =
        trusted_light_block.to_sol_client_state(args.trust_level.try_into()?, unbonding_period)?;
    let trusted_consensus_state = trusted_light_block.to_consensus_state().into();
    let proposed_header = target_light_block.into_header(&trusted_light_block);
    let contract_env = Env {
        chainId: trusted_light_block.chain_id()?.to_string(),
        trustThreshold: trusted_client_state.trustLevel.clone(),
        trustingPeriod: trusted_client_state.trustingPeriod,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs(),
    };

    let kv_proofs: Vec<(String, MerkleProof, Vec<u8>)> =
        futures::future::try_join_all(args.key_paths.into_iter().map(|key_path| async {
            let res = tm_rpc_client
                .abci_query(
                    Some("store/ibc/key".to_string()),
                    key_path.as_bytes(),
                    // Proof height should be the block before the target block.
                    Some((args.target_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(u32::try_from(res.height.value())? + 1, args.target_block);
            assert_eq!(res.key.as_slice(), key_path.as_bytes());
            let vm_proof = convert_tm_to_ics_merkle_proof(&res.proof.unwrap())?;
            let value = res.value;
            if value.is_empty() {
                log::info!("Verifying non-membership");
            }
            assert!(!vm_proof.proofs.is_empty());

            anyhow::Ok((key_path, vm_proof, value))
        }))
        .await?;

    // Generate a header update proof for the specified blocks.
    let proof_data = uc_mem_prover.generate_proof(
        &trusted_consensus_state,
        &proposed_header,
        &contract_env,
        kv_proofs,
    );

    let bytes = proof_data.public_values.as_slice();
    let output = UcAndMembershipOutput::abi_decode(bytes, false)?;

    let fixture = SP1ICS07UpdateClientAndMembershipFixture {
        trusted_consensus_state: hex::encode(trusted_consensus_state.abi_encode()),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        target_consensus_state: hex::encode(
            output.updateClientOutput.newConsensusState.abi_encode(),
        ),
        target_height: args.target_block,
        update_client_vkey: UpdateClientProgram::get_vkey().bytes32(),
        membership_vkey: MembershipProgram::get_vkey().bytes32(),
        uc_and_membership_vkey: uc_mem_prover.vkey.bytes32(),
        public_values: proof_data.public_values.raw(),
        proof: format!("0x{}", hex::encode(proof_data.bytes())),
        kv_pairs: hex::encode(output.kvPairs.abi_encode()),
    };

    // Save the proof data to the file path.
    std::fs::write(
        PathBuf::from(args.output_path),
        serde_json::to_string_pretty(&fixture).unwrap(),
    )
    .unwrap();
    Ok(())
}
