// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ICS07Tendermint.sol";

/// @title MembershipProgram
/// @author srdtrk
/// @notice Defines shared types for the verify (non)membership program.
contract MembershipProgram {
    /// @notice The public value output for the sp1 verify (non)membership program.
    struct MembershipOutput {
        bytes32 commitment_root;
        string key_path;
        bytes value;
    }
}
