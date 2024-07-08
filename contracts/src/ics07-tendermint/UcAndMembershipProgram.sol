// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ICS07Tendermint.sol";
import {MembershipProgram} from "./MembershipProgram.sol";
import {UpdateClientProgram} from "./UpdateClientProgram.sol";

/// @title UpdateClientAndMembershipProgram
/// @author srdtrk
/// @notice Defines shared types for the update client and membership program.
contract UpdateClientAndMembershipProgram {
    /// @notice The public value output for the sp1 update client and membership program.
    struct UcAndMembershipOutput {
        /// Update client program output.
        UpdateClientProgram.UpdateClientOutput update_client_output;
        /// The key-value pairs verified by the membership program in the proposed header.
        MembershipProgram.KVPair[] kv_pairs;
    }
}
