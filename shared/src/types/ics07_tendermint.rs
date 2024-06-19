//! This module contains the shared types for `sp1-ics07-tendermint`.

use alloy_sol_types::sol;

sol! {
    /// Height of the counterparty chain
    struct Height {
        /// Previously known as "epoch"
        uint64 revision_number;
        /// The height of a block
        uint64 revision_height;
    }

    /// Fraction of validator overlap needed to update header
    struct TrustThreshold {
        /// numerator of the fraction
        uint64 numerator;
        /// denominator of the fraction
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
}
