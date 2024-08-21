// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./IICS07TendermintMsgs.sol";
import { ISP1Msgs } from "./ISP1Msgs.sol";

/// @title Misbehaviour Program Messages
/// @author gjermundgaraba
/// @notice Defines shared types for the misbehaviour program.
interface IMisbehaviourMsgs is IICS07TendermintMsgs, ISP1Msgs {
    /// @notice The message that is submitted to the misbehaviour function.
    /// @param sp1Proof The SP1 proof for updating the client.
    struct MsgSubmitMisbehaviour {
        SP1Proof sp1Proof;
    }

    /// @notice The public value output for the sp1 misbehaviour program.
    /// @param isMisbehaviour The flag indicating if there is misbehaviour.
    /// @param trustedConsensusState1 The trusted consensus state of header 1
    /// @param trustedConsensusState2 The trusted consensus state of header 2
    struct MisbehaviourOutput {
        bool isMisbehaviour;
        ConsensusState trustedConsensusState1;
        ConsensusState trustedConsensusState2;
    }
}
