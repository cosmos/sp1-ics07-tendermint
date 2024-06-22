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

use std::{str::FromStr, time::Duration};

use alloy_sol_types::SolValue;
use ibc_client_tendermint::{
    client_state::verify_header,
    types::{ConsensusState, Header},
};
use ibc_core_host::types::identifiers::{ChainId, ClientId};
use sp1_ics07_tendermint_program_update_client::types;
use tendermint_light_client_verifier::{options::Options, ProdVerifier};

/// The main function of the program.
///
/// # Panics
/// Panics if the verification fails.
pub fn main() {
    // input 1: the trusted consensus state
    let trusted_consensus_state = sp1_zkvm::io::read::<ConsensusState>();
    // input 2: the proposed header
    let proposed_header = sp1_zkvm::io::read::<Header>();
    // input 3: environment
    let env = sp1_zkvm::io::read::<types::validation::Env>();

    let client_id = ClientId::from_str(&env.client_id).unwrap();
    let chain_id = ChainId::from_str(&env.chain_id).unwrap();
    let options = Options {
        trust_threshold: env.trust_threshold.clone().into(),
        trusting_period: Duration::from_nanos(env.trusting_period),
        clock_drift: Duration::default(),
    };
    let ctx =
        types::validation::ClientValidationCtx::new(env.clone(), trusted_consensus_state.clone());

    verify_header::<_, sha2::Sha256>(
        &ctx,
        &proposed_header,
        &client_id,
        &chain_id,
        &options,
        &ProdVerifier::default(),
    )
    .unwrap();

    let new_consensus_state = ConsensusState::from(proposed_header);
    let output = types::output::SP1ICS07TendermintOutput {
        trusted_consensus_state: trusted_consensus_state.into(),
        new_consensus_state: new_consensus_state.into(),
        env,
    };

    sp1_zkvm::io::commit_slice(&output.abi_encode());
}
