// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ICS07Tendermint } from "./ICS07Tendermint.sol";

/// @title MisbehaviourProgram
/// @author gjermundgaraba
/// @notice Defines shared types for the misbehaviour program.
contract MisbehaviourProgram {
    /// @notice The public value output for the sp1 misbehaviour program.
    struct MisbehaviourOutput {
        bool isMisbehaviour;
    }
}