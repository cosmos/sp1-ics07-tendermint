//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::{fixtures::UpdateClientAndMembershipCmd, OutputPath},
    helpers::light_block::LightBlockExt,
    programs::UpdateClientAndMembershipProgram,
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRpcExt,
    runners::{
        fixtures::membership::SP1ICS07MembershipFixture, genesis::SP1ICS07TendermintGenesis,
    },
};
use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::merkle::MerkleProof;
use ibc_core_host_cosmos::IBC_QUERY_PATH;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{
    ClientState, ConsensusState as SolConsensusState, Env, MembershipProof,
    SP1MembershipAndUpdateClientProof, SP1Proof, UcAndMembershipOutput,
};
use sp1_ics07_tendermint_utils::convert_tm_to_ics_merkle_proof;
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::{Client, HttpClient};

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

    let genesis = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block,
        args.trust_options.trusting_period,
        args.trust_options.trust_level,
    )
    .await?;
    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;
    let trusted_consensus_state: ConsensusState =
        SolConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?.into();

    let proposed_header = target_light_block.into_header(&trusted_light_block);
    let contract_env = Env {
        chainId: trusted_light_block.chain_id()?.to_string(),
        trustThreshold: trusted_client_state.trustLevel.clone(),
        trustingPeriod: trusted_client_state.trustingPeriod,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs(),
    };

    let kv_proofs: Vec<(Vec<Vec<u8>>, Vec<u8>, MerkleProof)> =
        futures::future::try_join_all(args.key_paths.into_iter().map(|path| async {
            let res = tm_rpc_client
                .abci_query(
                    Some(IBC_QUERY_PATH.to_string()),
                    path.as_bytes(),
                    // Proof height should be the block before the target block.
                    Some((args.target_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(u32::try_from(res.height.value())? + 1, args.target_block);
            assert_eq!(res.key.as_slice(), path.as_bytes());
            let vm_proof = convert_tm_to_ics_merkle_proof(&res.proof.unwrap())?;
            let value = res.value;
            if value.is_empty() {
                log::info!("Verifying non-membership");
            }
            assert!(!vm_proof.proofs.is_empty());

            let key_path = vec![b"ibc".to_vec(), path.into()];
            anyhow::Ok((key_path, value, vm_proof))
        }))
        .await?;

    let kv_len = kv_proofs.len();
    // Generate a header update proof for the specified blocks.
    let proof_data = uc_mem_prover.generate_proof(
        &trusted_consensus_state.into(),
        &proposed_header,
        &contract_env,
        kv_proofs,
    );

    let bytes = proof_data.public_values.as_slice();
    let output = UcAndMembershipOutput::abi_decode(bytes, false)?;
    assert_eq!(output.kvPairs.len(), kv_len);

    let sp1_membership_proof = SP1MembershipAndUpdateClientProof {
        sp1Proof: SP1Proof::new(
            &uc_mem_prover.vkey.bytes32(),
            proof_data.bytes(),
            proof_data.public_values.to_vec(),
        ),
    };

    let fixture = SP1ICS07MembershipFixture {
        genesis,
        proof_height: output.updateClientOutput.newHeight.abi_encode(),
        membership_proof: MembershipProof::from(sp1_membership_proof).abi_encode(),
    };

    match args.output_path {
        OutputPath::File(path) => {
            // Save the proof data to the file path.
            std::fs::write(
                PathBuf::from(path),
                serde_json::to_string_pretty(&fixture).unwrap(),
            )
            .unwrap();
        }
        OutputPath::Stdout => {
            println!("{}", serde_json::to_string_pretty(&fixture).unwrap());
        }
    }

    Ok(())
}
