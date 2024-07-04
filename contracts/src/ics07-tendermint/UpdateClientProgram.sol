// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ICS07Tendermint.sol";

/// @title UpdateClientProgram
/// @author srdtrk
/// @notice Defines shared types for ICS07Tendermint implementations.
contract UpdateClientProgram {
    /// @notice The public value output for the sp1 update client program.
    struct Output {
        /// The trusted consensus state.
        ICS07Tendermint.ConsensusState trusted_consensus_state;
        /// The new consensus state with the verified header.
        ICS07Tendermint.ConsensusState new_consensus_state;
        /// The validation environment.
        Env env;
        /// trusted height
        ICS07Tendermint.Height trusted_height;
        /// new height
        ICS07Tendermint.Height new_height;
    }

    /// @notice The environment output for the sp1 program.
    struct Env {
        /// The chain ID of the chain that the client is tracking.
        string chain_id;
        /// Fraction of validator overlap needed to update header
        ICS07Tendermint.TrustThreshold trust_threshold;
        /// Duration of the period since the `LatestTimestamp` during which the
        /// submitted headers are valid for upgrade
        uint64 trusting_period;
        /// Timestamp in nanoseconds
        uint64 now;
    }
}
