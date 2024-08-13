// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./IICS07TendermintMsgs.sol";
import { ISP1Msgs } from "./ISP1Msgs.sol";

/// @title Update Client Program Messages
/// @author srdtrk
/// @notice Defines shared types for the update client program.
interface IUpdateClientMsgs is IICS07TendermintMsgs, ISP1Msgs {
    /// @notice The message that is submitted to the updateClient function.
    /// @param sp1Proof The SP1 proof for updating the client.
    struct MsgUpdateClient {
        SP1Proof sp1Proof;
    }

    /// @notice The public value output for the sp1 update client program.
    /// @param trustedConsensusState The trusted consensus state.
    /// @param newConsensusState The new consensus state with the verified header.
    /// @param env The validation environment.
    /// @param trustedHeight The trusted height.
    /// @param newHeight The new height.
    struct UpdateClientOutput {
        ConsensusState trustedConsensusState;
        ConsensusState newConsensusState;
        Env env;
        Height trustedHeight;
        Height newHeight;
    }

    /// @notice The environment output for the sp1 program.
    /// @param chainId The chain ID of the chain that the client is tracking.
    /// @param trustThreshold Fraction of validator overlap needed to update header
    /// @param trustingPeriod Duration of the period since the `LatestTimestamp` during which the
    /// submitted headers are valid for upgrade in seconds.
    /// @param now Timestamp in seconds.
    struct Env {
        string chainId;
        TrustThreshold trustThreshold;
        uint32 trustingPeriod;
        uint64 now;
    }
}
