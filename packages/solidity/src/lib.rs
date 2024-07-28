#![doc = include_str!("../README.md")]
#![deny(missing_docs)]
#![deny(clippy::nursery, clippy::pedantic, warnings)]

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

// NOTE: The riscv program won't compile with the `rpc` features.
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
        Self::new(
            trust_threshold.numerator.into(),
            trust_threshold.denominator.into(),
        )
        .unwrap()
    }
}

impl TryFrom<TendermintTrustThreshold> for sp1_ics07_tendermint::TrustThreshold {
    type Error = <u64 as TryInto<u32>>::Error;

    fn try_from(trust_threshold: TendermintTrustThreshold) -> Result<Self, Self::Error> {
        Ok(Self {
            numerator: trust_threshold.numerator().try_into()?,
            denominator: trust_threshold.denominator().try_into()?,
        })
    }
}

#[allow(clippy::fallible_impl_from)]
impl From<ICS07TendermintConsensusState> for sp1_ics07_tendermint::ConsensusState {
    fn from(ics07_tendermint_consensus_state: ICS07TendermintConsensusState) -> Self {
        let root: [u8; 32] = ics07_tendermint_consensus_state
            .root
            .into_vec()
            .try_into()
            .unwrap();
        let next_validators_hash: [u8; 32] = ics07_tendermint_consensus_state
            .next_validators_hash
            .as_bytes()
            .try_into()
            .unwrap();
        Self {
            #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
            timestamp: ics07_tendermint_consensus_state.timestamp.unix_timestamp() as u64,
            root: root.into(),
            nextValidatorsHash: next_validators_hash.into(),
        }
    }
}

#[allow(clippy::fallible_impl_from)]
impl From<sp1_ics07_tendermint::ConsensusState> for ICS07TendermintConsensusState {
    fn from(consensus_state: sp1_ics07_tendermint::ConsensusState) -> Self {
        let time =
            OffsetDateTime::from_unix_timestamp(consensus_state.timestamp.try_into().unwrap())
                .unwrap();
        let seconds = time.unix_timestamp();
        let nanos = time.nanosecond();
        Self {
            timestamp: Time::from_unix_timestamp(seconds, nanos).unwrap(),
            root: CommitmentRoot::from_bytes(&consensus_state.root.0),
            next_validators_hash: Hash::from_bytes(
                Algorithm::Sha256,
                &consensus_state.nextValidatorsHash.0,
            )
            .unwrap(),
        }
    }
}
