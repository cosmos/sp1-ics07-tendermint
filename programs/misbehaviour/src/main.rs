//! A program that verifies a misbehaviour evidence.

#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]
#![allow(clippy::no_mangle_with_rust_abi)]
// These two lines are necessary for the program to properly compile.
//
// Under the hood, we wrap your main function with some extra code so that it behaves properly
// inside the zkVM.
#![no_main]

use ibc_client_tendermint::types::Misbehaviour;
use sp1_ics07_tendermint_misbehaviour::check_for_misbehaviour;

sp1_zkvm::entrypoint!(main);

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    let encoded_1 = sp1_zkvm::io::read_vec();

    // input 1: the misbehaviour evidence
    let misbehaviour = serde_cbor::from_slice::<Misbehaviour>(&encoded_1).unwrap();

    let output = check_for_misbehaviour(misbehaviour);

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
