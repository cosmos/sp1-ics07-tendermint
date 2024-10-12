//! Runner for generating `membership` fixtures

use crate::{
    cli::command::{fixtures::MembershipCmd, OutputPath},
    programs::MembershipProgram,
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRpcExt,
    runners::genesis::SP1ICS07TendermintGenesis,
};
use alloy_sol_types::SolValue;
use core::str;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::merkle::MerkleProof;
use serde::{Deserialize, Serialize};
use serde_with::serde_as;
use sp1_ics07_tendermint_solidity::{
    IICS07TendermintMsgs::{ClientState, ConsensusState as SolConsensusState},
    IMembershipMsgs::{MembershipOutput, MembershipProof, SP1MembershipProof},
    ISP1Msgs::SP1Proof,
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
    pub membership_proof: Vec<u8>,
}

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: MembershipCmd) -> anyhow::Result<()> {
    assert!(!args.membership.key_paths.is_empty());

    let tm_rpc_client = HttpClient::from_env();
    let verify_mem_prover = SP1ICS07TendermintProver::<MembershipProgram>::default();

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.membership.trusted_block))
        .await?;

    let genesis = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block,
        args.membership.trust_options.trusting_period,
        args.membership.trust_options.trust_level,
    )
    .await?;

    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;
    let trusted_consensus_state =
        SolConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?;
    let commitment_root_bytes = ConsensusState::from(trusted_consensus_state.clone())
        .root
        .as_bytes()
        .to_vec();

    let kv_proofs: Vec<(Vec<Vec<u8>>, Vec<u8>, MerkleProof)> =
        futures::future::try_join_all(args.membership.key_paths.into_iter().map(|path| async {
            let path: Vec<Vec<u8>> = if args.membership.base64 {
                path.split('/')
                    .map(subtle_encoding::base64::decode)
                    .collect::<Result<_, _>>()?
            } else {
                vec![b"ibc".into(), path.into_bytes()]
            };
            assert_eq!(path.len(), 2);

            let res = tm_rpc_client
                .abci_query(
                    Some(format!("store/{}/key", str::from_utf8(&path[0])?)),
                    path[1].as_slice(),
                    // Proof height should be the block before the target block.
                    Some((args.membership.trusted_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(
                u32::try_from(res.height.value())? + 1,
                args.membership.trusted_block
            );
            assert_eq!(res.key.as_slice(), path[1].as_slice());
            let vm_proof = convert_tm_to_ics_merkle_proof(&res.proof.unwrap())?;
            assert!(!vm_proof.proofs.is_empty());

            anyhow::Ok((path, res.value, vm_proof))
        }))
        .await?;

    // Generate a header update proof for the specified blocks.
    let proof_data = verify_mem_prover.generate_proof(&commitment_root_bytes, kv_proofs);

    let bytes = proof_data.public_values.as_slice();
    let output = MembershipOutput::abi_decode(bytes, true)?;
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
        membership_proof: MembershipProof::from(sp1_membership_proof).abi_encode(),
    };

    match args.membership.output_path {
        OutputPath::File(path) => {
            // Save the proof data to the file path.
            std::fs::write(PathBuf::from(path), serde_json::to_string_pretty(&fixture)?).unwrap();
        }
        OutputPath::Stdout => {
            println!("{}", serde_json::to_string_pretty(&fixture)?);
        }
    }

    Ok(())
}
