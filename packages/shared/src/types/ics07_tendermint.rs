//! This module contains the shared types for `sp1-ics07-tendermint`.

use ibc_client_tendermint_types::ConsensusState as ICS07TendermintConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use tendermint::{hash::Algorithm, Time};
use tendermint_light_client_verifier::types::{Hash, TrustThreshold as TendermintTrustThreshold};
use time::OffsetDateTime;

#[cfg(feature = "rpc")]
alloy_sol_types::sol!(
    #[sol(rpc)]
    #[derive(serde::Deserialize, serde::Serialize)]
    #[allow(missing_docs, clippy::pedantic)]
    sp1_ics07_tendermint,
    "../../contracts/abi/SP1ICS07Tendermint.json"
);

#[cfg(not(feature = "rpc"))]
alloy_sol_types::sol!(
    #[derive(serde::Deserialize, serde::Serialize)]
    #[allow(missing_docs, clippy::pedantic)]
    sp1_ics07_tendermint,
    "../../contracts/abi/SP1ICS07Tendermint.json"
);

#[allow(clippy::fallible_impl_from)]
impl From<sp1_ics07_tendermint::TrustThreshold> for TendermintTrustThreshold {
    fn from(trust_threshold: sp1_ics07_tendermint::TrustThreshold) -> Self {
        Self::new(trust_threshold.numerator, trust_threshold.denominator).unwrap()
    }
}

impl From<ICS07TendermintConsensusState> for sp1_ics07_tendermint::ConsensusState {
    fn from(ics07_tendermint_consensus_state: ICS07TendermintConsensusState) -> Self {
        Self {
            #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
            timestamp: ics07_tendermint_consensus_state
                .timestamp
                .unix_timestamp_nanos() as u64,
            root: ics07_tendermint_consensus_state.root.into_vec().into(),
            next_validators_hash: ics07_tendermint_consensus_state
                .next_validators_hash
                .as_bytes()
                .to_vec()
                .into(),
        }
    }
}

#[allow(clippy::fallible_impl_from)]
impl From<sp1_ics07_tendermint::ConsensusState> for ICS07TendermintConsensusState {
    fn from(consensus_state: sp1_ics07_tendermint::ConsensusState) -> Self {
        let time = OffsetDateTime::from_unix_timestamp_nanos(i128::from(consensus_state.timestamp))
            .unwrap();
        let seconds = time.unix_timestamp();
        let nanos = time.nanosecond();
        Self {
            timestamp: Time::from_unix_timestamp(seconds, nanos).unwrap(),
            root: CommitmentRoot::from_bytes(&consensus_state.root),
            next_validators_hash: Hash::from_bytes(
                Algorithm::Sha256,
                &consensus_state.next_validators_hash,
            )
            .unwrap(),
        }
    }
}
