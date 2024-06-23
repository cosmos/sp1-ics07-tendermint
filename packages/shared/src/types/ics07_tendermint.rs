//! This module contains the shared types for `sp1-ics07-tendermint`.

use ibc_client_tendermint_types::ConsensusState as ICS07TendermintConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use tendermint::{hash::Algorithm, Time};
use tendermint_light_client_verifier::types::{Hash, TrustThreshold as TendermintTrustThreshold};
use time::OffsetDateTime;

alloy_sol_types::sol! {
    /// Height of the counterparty chain
    struct Height {
        /// Previously known as "epoch"
        uint64 revision_number;
        /// The height of a block
        uint64 revision_height;
    }

    /// Fraction of validator overlap needed to update header
    #[derive(Debug, serde::Deserialize, serde::Serialize)]
    struct TrustThreshold {
        /// Numerator of the fraction
        uint64 numerator;
        /// Denominator of the fraction
        uint64 denominator;
    }

    /// Defines the ICS07Tendermint ClientState for ibc-lite
    struct ClientState {
        /// Chain ID
        string chain_id;
        /// Fraction of validator overlap needed to update header
        TrustThreshold trust_level;
        /// Latest height the client was updated to
        Height latest_height;
        /// duration of the period since the LatestTimestamp during which the
        /// submitted headers are valid for upgrade
        uint64 trusting_period;
        /// duration of the staking unbonding period
        uint64 unbonding_period;
        /// whether or not client is frozen (due to misbehavior)
        bool is_frozen;
    }

    /// Defines the Tendermint light client's consensus state at some height.
    struct ConsensusState {
        /// timestamp that corresponds to the block height in which the ConsensusState
        /// was stored.
        uint64 timestamp;
        /// commitment root (i.e app hash)
        bytes root;
        /// next validators hash
        bytes next_validators_hash;
    }

/// @title SP1ICS07Tendermint
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client.
#[allow(missing_docs, clippy::pub_underscore_fields)]
contract SP1ICS07Tendermint {
    /// @notice The verification key for the program.
    bytes32 public ics07ProgramVkey;

    /// @notice The ICS07Tendermint client state
    ClientState public clientState;
    /// @notice The mapping from height to consensus state
    mapping(uint64 => ConsensusState) public consensusStates;

    /// @notice The entrypoint for verifying the proof.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    function verifyIcs07UpdateClientProof(
        bytes memory proof,
        bytes memory publicValues
    ) public;
}
}

#[allow(clippy::fallible_impl_from)]
impl From<TrustThreshold> for TendermintTrustThreshold {
    fn from(trust_threshold: TrustThreshold) -> Self {
        Self::new(trust_threshold.numerator, trust_threshold.denominator).unwrap()
    }
}

impl From<ICS07TendermintConsensusState> for ConsensusState {
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
impl From<ConsensusState> for ICS07TendermintConsensusState {
    fn from(consensus_state: ConsensusState) -> Self {
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
