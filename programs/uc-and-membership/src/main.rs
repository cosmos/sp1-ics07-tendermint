//! A program that verifies the membership or non-membership of a value in a commitment root.

#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]
#![allow(clippy::no_mangle_with_rust_abi)]
// These two lines are necessary for the program to properly compile.
//
// Under the hood, we wrap your main function with some extra code so that it behaves properly
// inside the zkVM.
#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_sol_types::SolValue;

use ibc_proto::Protobuf;
use sp1_ics07_tendermint_uc_and_membership::membership;

use ibc_core_commitment_types::merkle::MerkleProof;

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    let encoded_1 = sp1_zkvm::io::read_vec();
    let app_hash: [u8; 32] = encoded_1.try_into().unwrap();

    // encoded_2 is the number of key-value pairs we want to verify
    let request_len = sp1_zkvm::io::read_vec()[0];

    let request_iter = (0..request_len).map(|_| {
        let loop_encoded_1 = sp1_zkvm::io::read_vec();
        let path_str = String::from_utf8(loop_encoded_1).unwrap();

        let loop_encoded_2 = sp1_zkvm::io::read_vec();
        let merkle_proof = MerkleProof::decode_vec(&loop_encoded_2).unwrap();

        // loop_encoded_3 is the value we want to prove the membership of
        // if it is empty, we are verifying non-membership
        let value = sp1_zkvm::io::read_vec();

        (path_str, merkle_proof, value)
    });

    let output = membership(app_hash, request_iter);

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
