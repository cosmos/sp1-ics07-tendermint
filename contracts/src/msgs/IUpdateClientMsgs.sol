// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IICS07TendermintMsgs } from "./IICS07TendermintMsgs.sol";

/// @title Update Client Program Messages
/// @author srdtrk
/// @notice Defines shared types for the update client program.
interface IUpdateClientMsgs is IICS07TendermintMsgs {
    /// @notice The message that is submitted to the updateClient function.
    /// @param sp1Proof The SP1 proof for updating the client.
    struct MsgUpdateClient {
        SP1Proof sp1Proof;
    }

    /// @notice The public value output for the sp1 update client program.
    /// @param trustedConsensusState The trusted consensus state.
    /// @param newConsensusState The new consensus state with the verified header.
    /// @param time The time which the header was verified in seconds.
    /// @param trustedHeight The trusted height.
    /// @param newHeight The new height.
    struct UpdateClientOutput {
        ClientState clientState;
        ConsensusState trustedConsensusState;
        ConsensusState newConsensusState;
        uint64 time;
        Height trustedHeight;
        Height newHeight;
    }
}
