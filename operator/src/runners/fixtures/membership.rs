//! Runner for generating `membership` fixtures

use crate::{
    cli::command::{
        fixtures::{MembershipCmd, ProofTypeWithUnion},
        OutputPath,
    },
    runners::genesis::SP1ICS07TendermintGenesis,
};
use alloy_sol_types::SolValue;
use core::str;
use ibc_client_tendermint_types::ConsensusState;
use ibc_core_commitment_types::merkle::MerkleProof;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_prover::{
    programs::MembershipProgram,
    prover::{SP1ICS07TendermintProver, SupportedProofType},
};
use sp1_ics07_tendermint_solidity::{
    IICS07TendermintMsgs::{ClientState, ConsensusState as SolConsensusState},
    IMembershipMsgs::{
        MembershipOutput, MembershipProof, SP1MembershipProof, UnionMembershipProof,
    },
    ISP1Msgs::SP1Proof,
};
use sp1_ics07_tendermint_utils::{
    merkle::convert_tm_to_ics_merkle_proof, rpc::TendermintRpcExt, union::convert_to_union_proof,
};
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::{Client, HttpClient};
use unionlabs::encoding::{EncodeAs, EthAbi};

/// The fixture data to be used in [`MembershipProgram`] tests.
#[serde_with::serde_as]
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

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.membership.trusted_block))
        .await?;

    let genesis = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block,
        args.membership.trust_options.trusting_period,
        args.membership.trust_options.trust_level,
        match args.proof_type {
            // Genesis requires a proof type, but it is not used in membership in the union case.
            ProofTypeWithUnion::Union => SupportedProofType::Plonk,
            ProofTypeWithUnion::ProofType(proof_type) => proof_type,
        },
    )
    .await?;

    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;
    let trusted_consensus_state =
        SolConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?;

    let membership_proof = match args.proof_type {
        ProofTypeWithUnion::Union => {
            run_union_membership(
                &tm_rpc_client,
                args.membership.base64,
                args.membership.key_paths,
                args.membership.trusted_block,
                trusted_consensus_state,
            )
            .await?
        }
        ProofTypeWithUnion::ProofType(proof_type) => {
            run_sp1_membership(
                &tm_rpc_client,
                args.membership.base64,
                args.membership.key_paths,
                args.membership.trusted_block,
                trusted_consensus_state,
                proof_type,
            )
            .await?
        }
    };

    let fixture = SP1ICS07MembershipFixture {
        genesis,
        proof_height: trusted_client_state.latestHeight.abi_encode(),
        membership_proof: membership_proof.abi_encode(),
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

/// Generates a union membership proof for the given args
#[allow(
    clippy::missing_errors_doc,
    clippy::missing_panics_doc,
    clippy::module_name_repetitions
)]
pub async fn run_union_membership(
    tm_rpc_client: &HttpClient,
    is_base64: bool,
    key_paths: Vec<String>,
    trusted_block: u32,
    trusted_consensus_state: SolConsensusState,
) -> anyhow::Result<MembershipProof> {
    assert!(
        key_paths.len() == 1,
        "Union membership only supports one key-value pair"
    );

    let path: Vec<Vec<u8>> = if is_base64 {
        key_paths[0]
            .split('\\')
            .map(subtle_encoding::base64::decode)
            .collect::<Result<_, _>>()?
    } else {
        vec![b"ibc".into(), key_paths[0].as_bytes().to_vec()]
    };

    // the program could support longer key paths, but the operator only supports 2
    // because the current assumption is that the Cosmos SDK will always have 2
    assert_eq!(path.len(), 2);

    let res = tm_rpc_client
        .abci_query(
            Some(format!("store/{}/key", str::from_utf8(&path[0])?)),
            path[1].as_slice(),
            // Proof height should be the block before the target block.
            Some((trusted_block - 1).into()),
            true,
        )
        .await?;

    let union_proof = convert_to_union_proof(res.proof.unwrap())?;
    Ok(MembershipProof::from(UnionMembershipProof {
        ics23Proof: union_proof.encode_as::<EthAbi>().into(),
        trustedConsensusState: trusted_consensus_state,
    }))
}

/// Generates an sp1 membership proof for the given args
#[allow(
    clippy::missing_errors_doc,
    clippy::missing_panics_doc,
    clippy::module_name_repetitions
)]
pub async fn run_sp1_membership(
    tm_rpc_client: &HttpClient,
    is_base64: bool,
    key_paths: Vec<String>,
    trusted_block: u32,
    trusted_consensus_state: SolConsensusState,
    proof_type: SupportedProofType,
) -> anyhow::Result<MembershipProof> {
    let verify_mem_prover = SP1ICS07TendermintProver::<MembershipProgram>::new(proof_type);
    let commitment_root_bytes = ConsensusState::from(trusted_consensus_state.clone())
        .root
        .as_bytes()
        .to_vec();

    let kv_proofs: Vec<(Vec<Vec<u8>>, Vec<u8>, MerkleProof)> =
        futures::future::try_join_all(key_paths.into_iter().map(|path| async {
            let path: Vec<Vec<u8>> = if is_base64 {
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
                    Some((trusted_block - 1).into()),
                    true,
                )
                .await?;

            assert_eq!(u32::try_from(res.height.value())? + 1, trusted_block);
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

    Ok(MembershipProof::from(sp1_membership_proof))
}
