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

use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::Header;
use sp1_ics07_tendermint_solidity::IICS07TendermintMsgs::{
    ClientState as SolClientState, ConsensusState as SolConsensusState,
};
use sp1_ics07_tendermint_update_client::update_client;

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    let encoded_1 = sp1_zkvm::io::read_vec();
    let encoded_2 = sp1_zkvm::io::read_vec();
    let encoded_3 = sp1_zkvm::io::read_vec();
    let encoded_4 = sp1_zkvm::io::read_vec();

    // input 1: the client state
    let client_state = bincode::deserialize::<SolClientState>(&encoded_1).unwrap();
    // input 2: the trusted consensus state
    let trusted_consensus_state = bincode::deserialize::<SolConsensusState>(&encoded_2)
        .unwrap()
        .into();
    // input 3: the proposed header
    let proposed_header = serde_cbor::from_slice::<Header>(&encoded_3).unwrap();
    // input 4: time
    let time = u64::from_le_bytes(encoded_4.try_into().unwrap());
    // TODO: find an encoding that works for all the structs above.

    let output = update_client(client_state, trusted_consensus_state, proposed_header, time);

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
