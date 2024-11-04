//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::{fixtures::UpdateClientAndMembershipCmd, OutputPath},
    runners::{
        fixtures::membership::SP1ICS07MembershipFixture, genesis::SP1ICS07TendermintGenesis,
    },
};
use alloy_sol_types::SolValue;
use core::str;
use ibc_client_tendermint_types::ConsensusState;
use ibc_core_commitment_types::merkle::MerkleProof;
use sp1_ics07_tendermint_prover::{
    programs::UpdateClientAndMembershipProgram, prover::SP1ICS07TendermintProver,
};
use sp1_ics07_tendermint_solidity::{
    IICS07TendermintMsgs::{ClientState, ConsensusState as SolConsensusState},
    IMembershipMsgs::{MembershipProof, SP1MembershipAndUpdateClientProof},
    ISP1Msgs::SP1Proof,
    IUpdateClientAndMembershipMsgs::UcAndMembershipOutput,
};
use sp1_ics07_tendermint_utils::merkle::convert_tm_to_ics_merkle_proof;
use sp1_ics07_tendermint_utils::{light_block::LightBlockExt, rpc::TendermintRpcExt};
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::{Client, HttpClient};

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: UpdateClientAndMembershipCmd) -> anyhow::Result<()> {
    assert!(
        args.membership.trusted_block < args.target_block,
        "The target block must be greater than the trusted block"
    );

    let tm_rpc_client = HttpClient::from_env();
    let uc_mem_prover = SP1ICS07TendermintProver::<UpdateClientAndMembershipProgram>::default();

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.membership.trusted_block))
        .await?;
    let target_light_block = tm_rpc_client
        .get_light_block(Some(args.target_block))
        .await?;

    let genesis = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block,
        args.membership.trust_options.trusting_period,
        args.membership.trust_options.trust_level,
    )
    .await?;
    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;
    let trusted_consensus_state: ConsensusState =
        SolConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?.into();

    let proposed_header = target_light_block.into_header(&trusted_light_block);
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)?
        .as_secs();

    let kv_proofs: Vec<(Vec<Vec<u8>>, Vec<u8>, MerkleProof)> =
        futures::future::try_join_all(args.membership.key_paths.into_iter().map(|path| async {
            let path: Vec<Vec<u8>> = if args.membership.base64 {
                path.split('\\')
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
                    Some((args.target_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(u32::try_from(res.height.value())? + 1, args.target_block);
            assert_eq!(res.key.as_slice(), path[1].as_slice());
            let vm_proof = convert_tm_to_ics_merkle_proof(&res.proof.unwrap())?;
            assert!(!vm_proof.proofs.is_empty());

            anyhow::Ok((path, res.value, vm_proof))
        }))
        .await?;

    let kv_len = kv_proofs.len();
    // Generate a header update proof for the specified blocks.
    let proof_data = uc_mem_prover.generate_proof(
        &trusted_client_state,
        &trusted_consensus_state.into(),
        &proposed_header,
        now,
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

    match args.membership.output_path {
        OutputPath::File(path) => {
            // Save the proof data to the file path.
            std::fs::write(PathBuf::from(path), serde_json::to_string_pretty(&fixture)?)?;
        }
        OutputPath::Stdout => {
            println!("{}", serde_json::to_string_pretty(&fixture)?);
        }
    }

    Ok(())
}
