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

use ibc_client_tendermint::types::{ConsensusState, Header};
use sp1_ics07_tendermint_update_client_program::types;

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    // input 1: the trusted consensus state
    let _trusted_consensus_state = sp1_zkvm::io::read::<ConsensusState>();
    // input 2: the proposed header
    let _proposed_header = sp1_zkvm::io::read::<Header>();
    // input 3: environment
    let _env = sp1_zkvm::io::read::<types::Env>();

    todo!()
}
