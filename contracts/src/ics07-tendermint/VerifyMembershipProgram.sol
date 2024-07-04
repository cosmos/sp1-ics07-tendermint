// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ICS07Tendermint.sol";

/// @title VerifyMembershipProgram
/// @author srdtrk
/// @notice Defines shared types for the verify membership program.
contract VerifyMembershipProgram {
    /// @notice The public value output for the sp1 update client program.
    struct VerifyMembershipOutput {
        bytes32 commitment_root;
        string key_path;
        bytes value;
    }
}
