//! A program that verifies a misbehaviour evidence.

#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]
#![allow(clippy::no_mangle_with_rust_abi)]
// These two lines are necessary for the program to properly compile.
//
// Under the hood, we wrap your main function with some extra code so that it behaves properly
// inside the zkVM.
#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::Misbehaviour;
use sp1_ics07_tendermint_misbehaviour::check_for_misbehaviour;
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
    let encoded_4 = sp1_zkvm::io::read_vec();

    // input 1: environment
    let env = bincode::deserialize::<Env>(&encoded_1).unwrap();
    // input 2: the misbehaviour evidence
    let misbehaviour = serde_cbor::from_slice::<Misbehaviour>(&encoded_2).unwrap();
    // input 3: header 1 trusted consensus state
    let trusted_consensus_state_1 = bincode::deserialize::<SolConsensusState>(&encoded_3)
        .unwrap()
        .into();
    // input 4: header 2 trusted consensus state
    let trusted_consensus_state_2 = bincode::deserialize::<SolConsensusState>(&encoded_4)
        .unwrap()
        .into();

    let output = check_for_misbehaviour(
        env,
        &misbehaviour,
        trusted_consensus_state_1,
        trusted_consensus_state_2,
    );

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
