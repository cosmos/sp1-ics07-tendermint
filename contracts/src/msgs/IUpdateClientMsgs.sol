// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./IICS07TendermintMsgs.sol";
import { ISP1Msgs } from "./ISP1Msgs.sol";

/// @title Update Client Program Messages
/// @author srdtrk
/// @notice Defines shared types for the update client program.
interface IUpdateClientMsgs is IICS07TendermintMsgs, ISP1Msgs {
    /// @notice The message that is submitted to the updateClient function.
    struct MsgUpdateClient {
        /// SP1 proof for updating the client.
        SP1Proof sp1Proof;
    }

    /// @notice The public value output for the sp1 update client program.
    struct UpdateClientOutput {
        /// The trusted consensus state.
        ConsensusState trustedConsensusState;
        /// The new consensus state with the verified header.
        ConsensusState newConsensusState;
        /// The validation environment.
        Env env;
        /// trusted height
        Height trustedHeight;
        /// new height
        Height newHeight;
    }

    /// @notice The environment output for the sp1 program.
    struct Env {
        /// The chain ID of the chain that the client is tracking.
        string chainId;
        /// Fraction of validator overlap needed to update header
        TrustThreshold trustThreshold;
        /// Duration of the period since the `LatestTimestamp` during which the
        /// submitted headers are valid for upgrade in seconds.
        uint32 trustingPeriod;
        /// Timestamp in seconds
        uint64 now;
    }
}
