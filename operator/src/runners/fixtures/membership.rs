//! Runner for generating `membership` fixtures

use crate::{
    cli::command::fixtures::MembershipCmd, programs::MembershipProgram,
    prover::SP1ICS07TendermintProver, rpc::TendermintRpcExt,
    runners::genesis::SP1ICS07TendermintGenesis,
};
use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::merkle::MerkleProof;
use serde::{Deserialize, Serialize};
use serde_with::serde_as;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{
    ClientState, ConsensusState as SolConsensusState, MembershipOutput, MembershipProof,
    SP1MembershipProof, SP1Proof,
};
use sp1_ics07_tendermint_utils::convert_tm_to_ics_merkle_proof;
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::{Client, HttpClient};

/// The fixture data to be used in [`MembershipProgram`] tests.
#[serde_as]
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SP1ICS07MembershipFixture {
    /// The genesis data.
    #[serde(flatten)]
    pub genesis: SP1ICS07TendermintGenesis,
    /// The height of the proof.
    #[serde_as(as = "serde_with::hex::Hex")]
    pub proof_height: Vec<u8>,
    /// The encoded public values.
    #[serde_as(as = "serde_with::hex::Hex")]
    pub proof: Vec<u8>,
}

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: MembershipCmd) -> anyhow::Result<()> {
    assert!(!args.key_paths.is_empty());

    let tm_rpc_client = HttpClient::from_env();
    let verify_mem_prover = SP1ICS07TendermintProver::<MembershipProgram>::default();

    let genesis = SP1ICS07TendermintGenesis::from_env(
        Some(args.trusted_block),
        args.trust_options.trusting_period,
        args.trust_options.trust_level,
    )
    .await?;

    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;
    let trusted_consensus_state =
        SolConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?;
    let commitment_root_bytes = ConsensusState::from(trusted_consensus_state.clone())
        .root
        .as_bytes()
        .to_vec();

    let kv_proofs: Vec<(String, MerkleProof, Vec<u8>)> =
        futures::future::try_join_all(args.key_paths.into_iter().map(|key_path| async {
            let res = tm_rpc_client
                .abci_query(
                    Some("store/ibc/key".to_string()),
                    key_path.as_bytes(),
                    // Proof height should be the block before the target block.
                    Some((args.trusted_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(u32::try_from(res.height.value())? + 1, args.trusted_block);
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
    let proof_data = verify_mem_prover.generate_proof(&commitment_root_bytes, kv_proofs);

    let bytes = proof_data.public_values.as_slice();
    let output = MembershipOutput::abi_decode(bytes, true).unwrap();
    assert_eq!(output.commitmentRoot.as_slice(), &commitment_root_bytes);

    let sp1_membership_proof = SP1MembershipProof {
        sp1Proof: SP1Proof::new(
            &verify_mem_prover.vkey.bytes32(),
            proof_data.bytes(),
            proof_data.public_values.to_vec(),
        ),
        trustedConsensusState: trusted_consensus_state,
    };

    let fixture = SP1ICS07MembershipFixture {
        genesis,
        proof_height: trusted_client_state.latestHeight.abi_encode(),
        proof: MembershipProof::from(sp1_membership_proof).abi_encode(),
    };

    // Save the proof data to the file path.
    std::fs::write(
        PathBuf::from(args.output_path),
        serde_json::to_string_pretty(&fixture).unwrap(),
    )
    .unwrap();
    Ok(())
}
