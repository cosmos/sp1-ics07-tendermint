// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IICS02ClientMsgs } from "solidity-ibc/msgs/IICS02ClientMsgs.sol";

/// @title ICS07 Tendermint Messages
/// @author srdtrk
/// @notice Defines shared types for ICS07Tendermint implementations.
interface IICS07TendermintMsgs is IICS02ClientMsgs {
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
        string chainId;
        /// Fraction of validator overlap needed to update header
        TrustThreshold trustLevel;
        /// Latest height the client was updated to
        Height latestHeight;
        /// duration of the period since the LatestTimestamp during which the
        /// submitted headers are valid for upgrade in seconds
        uint32 trustingPeriod;
        /// duration of the staking unbonding period in seconds
        uint32 unbondingPeriod;
        /// whether or not client is frozen (due to misbehavior)
        bool isFrozen;
    }

    /// Defines the Tendermint light client's consensus state at some height.
    struct ConsensusState {
        /// timestamp that corresponds to the block height in which the ConsensusState
        /// was stored.
        uint64 timestamp;
        /// commitment root (i.e app hash)
        bytes32 root;
        /// next validators hash
        bytes32 nextValidatorsHash;
    }
}
