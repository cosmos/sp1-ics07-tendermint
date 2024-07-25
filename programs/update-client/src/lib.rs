//! The crate that contains the types and utilities for `sp1-ics07-tendermint-update-client`
//! program.
#![deny(missing_docs, clippy::nursery, clippy::pedantic, warnings)]

pub mod types;

use std::{str::FromStr, time::Duration};

use ibc_client_tendermint::{
    client_state::verify_header,
    types::{ConsensusState, Header, TENDERMINT_CLIENT_TYPE},
};
use ibc_core_host_types::identifiers::{ChainId, ClientId};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{self, Env, UpdateClientOutput};

use tendermint_light_client_verifier::{options::Options, ProdVerifier};

/// The main function of the program without the zkVM wrapper.
#[allow(clippy::missing_panics_doc)]
#[must_use]
pub fn update_client(
    trusted_consensus_state: ConsensusState,
    proposed_header: Header,
    env: Env,
) -> UpdateClientOutput {
    let client_id = ClientId::new(TENDERMINT_CLIENT_TYPE, 0).unwrap();
    let chain_id = ChainId::from_str(&env.chainId).unwrap();
    let options = Options {
        trust_threshold: env.trustThreshold.clone().into(),
        trusting_period: Duration::from_secs(env.trustingPeriod.into()),
        clock_drift: Duration::default(),
    };

    let ctx = types::validation::ClientValidationCtx::new(&env, &trusted_consensus_state);

    verify_header::<_, sha2::Sha256>(
        &ctx,
        &proposed_header,
        &client_id,
        &chain_id,
        &options,
        &ProdVerifier::default(),
    )
    .unwrap();

    let trusted_height = sp1_ics07_tendermint::Height {
        revisionNumber: proposed_header
            .trusted_height
            .revision_number()
            .try_into()
            .unwrap(),
        revisionHeight: proposed_header
            .trusted_height
            .revision_height()
            .try_into()
            .unwrap(),
    };
    let new_height = sp1_ics07_tendermint::Height {
        revisionNumber: proposed_header
            .height()
            .revision_number()
            .try_into()
            .unwrap(),
        revisionHeight: proposed_header
            .height()
            .revision_height()
            .try_into()
            .unwrap(),
    };
    let new_consensus_state = ConsensusState::from(proposed_header);

    UpdateClientOutput {
        trustedConsensusState: trusted_consensus_state.into(),
        newConsensusState: new_consensus_state.into(),
        env,
        trustedHeight: trusted_height,
        newHeight: new_height,
    }
}
