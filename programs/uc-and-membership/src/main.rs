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
use sp1_ics07_tendermint_uc_and_membership::update_client_and_membership;

use ibc_core_commitment_types::merkle::MerkleProof;

use ibc_client_tendermint_types::Header;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{
    ConsensusState as SolConsensusState, Env,
};

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    let encoded_1 = sp1_zkvm::io::read_vec();
    let encoded_2 = sp1_zkvm::io::read_vec();
    let encoded_3 = sp1_zkvm::io::read_vec();
    // encoded_4 is the number of key-value pairs we want to verify
    let request_len = sp1_zkvm::io::read_vec()[0];

    // input 1: the trusted consensus state
    let trusted_consensus_state = bincode::deserialize::<SolConsensusState>(&encoded_1)
        .unwrap()
        .into();
    // input 2: the proposed header
    let proposed_header = serde_cbor::from_slice::<Header>(&encoded_2).unwrap();
    // input 3: environment
    let env = bincode::deserialize::<Env>(&encoded_3).unwrap();
    // TODO: find an encoding that works for all the structs above.

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

    let output =
        update_client_and_membership(trusted_consensus_state, proposed_header, env, request_iter);

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
