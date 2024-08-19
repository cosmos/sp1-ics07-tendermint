// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @title Misbehaviour Program Messages
/// @author gjermundgaraba
/// @notice Defines shared types for the misbehaviour program.
interface IMisbehaviourMsgs {
    /// @notice The public value output for the sp1 misbehaviour program.
    /// @param isMisbehaviour The flag indicating if there is misbehaviour.
    struct MisbehaviourOutput {
        bool isMisbehaviour;
    }
}
