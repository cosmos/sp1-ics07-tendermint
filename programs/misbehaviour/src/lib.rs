//! The crate that contains the types and utilities for `sp1-ics07-tendermint-update-client`
//! program.
#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]

use ibc_client_tendermint::client_state::check_for_misbehaviour_on_misbehavior;
use ibc_client_tendermint::types::Misbehaviour;

use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::MisbehaviourOutput;

/// The main function of the program without the zkVM wrapper.
#[allow(clippy::missing_panics_doc)]
#[must_use]
pub fn check_for_misbehaviour(misbehaviour: Misbehaviour) -> MisbehaviourOutput {
    let is_misbehaviour =
        check_for_misbehaviour_on_misbehavior(misbehaviour.header1(), misbehaviour.header2())
            .unwrap();

    MisbehaviourOutput {
        isMisbehaviour: is_misbehaviour,
    }
}
