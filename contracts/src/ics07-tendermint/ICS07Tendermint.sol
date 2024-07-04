// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title ICS07Tendermint
/// @author srdtrk
/// @notice Defines shared types for ICS07Tendermint implementations.
contract ICS07Tendermint {
    /// @notice Height of the counterparty chain
    struct Height {
        /// Previously known as "epoch"
        uint32 revision_number;
        /// The height of a block
        uint32 revision_height;
    }

    /// Fraction of validator overlap needed to update header
    struct TrustThreshold {
        /// Numerator of the fraction
        uint8 numerator;
        /// Denominator of the fraction
        uint8 denominator;
    }

    /// @notice Defines the ICS07Tendermint ClientState for ibc-lite
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
        bytes32 root;
        /// next validators hash
        bytes32 next_validators_hash;
    }
}
