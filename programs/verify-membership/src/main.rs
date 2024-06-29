//! A program that verifies the next block header of a blockchain using an IBC tendermint light
//! client.

#![deny(missing_docs)]
#![deny(clippy::nursery, clippy::pedantic, warnings)]
#![allow(clippy::no_mangle_with_rust_abi)]
// These two lines are necessary for the program to properly compile.
//
// Under the hood, we wrap your main function with some extra code so that it behaves properly
// inside the zkVM.
#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_sol_types::{sol, SolType};

/// The public values encoded as a tuple that can be easily deserialized inside Solidity.
type PublicValuesTuple = sol! {
    tuple(bytes32, string, bytes)
};

use ibc_core_commitment_types::{
    commitment::{CommitmentProofBytes, CommitmentRoot},
    merkle::MerkleProof,
    proto::{ics23::HostFunctionsManager, v1::MerklePath},
    specs::ProofSpecs,
};

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    let encoded_1 = sp1_zkvm::io::read_vec();
    let app_hash: [u8; 32] = encoded_1.clone().try_into().unwrap();
    let commitment_root = CommitmentRoot::from(encoded_1);

    let encoded_2 = sp1_zkvm::io::read_vec();
    let commitment_proof = CommitmentProofBytes::try_from(encoded_2).unwrap();
    let merkle_proof = MerkleProof::try_from(&commitment_proof).unwrap();

    let encoded_3 = sp1_zkvm::io::read_vec();
    let path_str = String::from_utf8(encoded_3).unwrap();
    let key_path = path_str
        .split('/')
        .map(std::string::ToString::to_string)
        .collect::<Vec<String>>();
    let path = MerklePath { key_path };

    // encoded_4 is the value we want to prove the membership of
    let value = sp1_zkvm::io::read_vec();

    merkle_proof
        .verify_membership::<HostFunctionsManager>(
            &ProofSpecs::cosmos(),
            commitment_root.into(),
            path,
            value.clone(),
            0,
        )
        .unwrap();

    let output = PublicValuesTuple::abi_encode(&(app_hash, path_str, value));
    sp1_zkvm::io::commit_slice(&output);
}
