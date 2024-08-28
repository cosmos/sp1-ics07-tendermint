//! The crate that contains the types and utilities for `sp1-ics07-tendermint-update-client`
//! program.
#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]

pub mod types;

use ibc_client_tendermint::client_state::{
    check_for_misbehaviour_on_misbehavior, verify_misbehaviour,
};
use ibc_client_tendermint::types::{ConsensusState, Misbehaviour, TENDERMINT_CLIENT_TYPE};
use ibc_core_host_types::identifiers::{ChainId, ClientId};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{Env, MisbehaviourOutput};
use std::collections::HashMap;
use std::time::Duration;
use tendermint_light_client_verifier::options::Options;
use tendermint_light_client_verifier::ProdVerifier;

/// The main function of the program without the zkVM wrapper.
#[allow(clippy::missing_panics_doc)]
#[must_use]
pub fn check_for_misbehaviour(
    env: Env,
    misbehaviour: Misbehaviour,
    trusted_consensus_state_1: ConsensusState,
    trusted_consensus_state_2: ConsensusState,
) -> MisbehaviourOutput {
    let client_id = ClientId::new(TENDERMINT_CLIENT_TYPE, 0).unwrap();
    let chain_id = env.clone().chainId;
    assert_eq!(
        chain_id,
        misbehaviour
            .header1()
            .signed_header
            .header
            .chain_id
            .to_string()
    );

    let mut trusted_consensus_state_map = HashMap::new();
    trusted_consensus_state_map.insert(
        misbehaviour.header1().trusted_height.revision_height(),
        &trusted_consensus_state_1,
    );
    trusted_consensus_state_map.insert(
        misbehaviour.header2().trusted_height.revision_height(),
        &trusted_consensus_state_2,
    );
    let ctx =
        types::validation::MisbehaviourValidationContext::new(&env, trusted_consensus_state_map);

    let options = Options {
        trust_threshold: env.trustThreshold.clone().into(),
        trusting_period: Duration::from_secs(env.trustingPeriod.into()),
        clock_drift: Duration::default(),
    };

    verify_misbehaviour::<_, sha2::Sha256>(
        &ctx,
        &misbehaviour,
        &client_id,
        &ChainId::new(chain_id.as_str()).unwrap(),
        &options,
        &ProdVerifier::default(),
    )
    .unwrap();

    let is_misbehaviour =
        check_for_misbehaviour_on_misbehavior(misbehaviour.header1(), misbehaviour.header2())
            .unwrap();

    if !is_misbehaviour {
        panic!("Misbehaviour is not detected");
    }

    let output_trusted_header_1 = sp1_ics07_tendermint::Height {
        revisionNumber: misbehaviour
            .header1()
            .trusted_height
            .revision_height()
            .try_into()
            .unwrap(),
        revisionHeight: misbehaviour
            .header1()
            .trusted_height
            .revision_height()
            .try_into()
            .unwrap(),
    };
    let output_trusted_header_2 = sp1_ics07_tendermint::Height {
        revisionNumber: misbehaviour
            .header2()
            .trusted_height
            .revision_height()
            .try_into()
            .unwrap(),
        revisionHeight: misbehaviour
            .header2()
            .trusted_height
            .revision_height()
            .try_into()
            .unwrap(),
    };

    MisbehaviourOutput {
        env,
        trustedHeight1: output_trusted_header_1,
        trustedHeight2: output_trusted_header_2,
        trustedConsensusState1: trusted_consensus_state_1.into(),
        trustedConsensusState2: trusted_consensus_state_2.into(),
    }
}
