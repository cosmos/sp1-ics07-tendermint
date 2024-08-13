//! The crate that contains the types and utilities for `sp1-ics07-tendermint-membership` program.
#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]

use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{KVPair, MembershipOutput};

use ibc_core_commitment_types::{
    commitment::CommitmentRoot,
    merkle::MerkleProof,
    proto::{ics23::HostFunctionsManager, v1::MerklePath},
    specs::ProofSpecs,
};

/// The main function of the program without the zkVM wrapper.
#[allow(clippy::missing_panics_doc)]
#[must_use]
pub fn membership(
    app_hash: [u8; 32],
    request_iter: impl Iterator<Item = (String, MerkleProof, Vec<u8>)>,
) -> MembershipOutput {
    let commitment_root = CommitmentRoot::from_bytes(&app_hash);

    let kv_pairs = request_iter
        .map(|(path_str, merkle_proof, value)| {
            let path = MerklePath {
                key_path: vec!["ibc".to_string(), path_str.clone()],
            };

            if value.is_empty() {
                merkle_proof
                    .verify_non_membership::<HostFunctionsManager>(
                        &ProofSpecs::cosmos(),
                        commitment_root.clone().into(),
                        path.into(),
                    )
                    .unwrap();
            } else {
                merkle_proof
                    .verify_membership::<HostFunctionsManager>(
                        &ProofSpecs::cosmos(),
                        commitment_root.clone().into(),
                        path.into(),
                        value.clone(),
                        0,
                    )
                    .unwrap();
            }

            KVPair {
                path: path_str.into(),
                value: value.into(),
            }
        })
        .collect();

    MembershipOutput {
        commitmentRoot: app_hash.into(),
        kvPairs: kv_pairs,
    }
}
