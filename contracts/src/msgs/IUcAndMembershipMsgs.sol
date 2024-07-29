// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IUpdateClientMsgs } from "./IUpdateClientMsgs.sol";
import { IMembershipMsgs } from "./IMembershipMsgs.sol";

/// @title Update Client and Membership Program Messages
/// @author srdtrk
/// @notice Defines shared types for the update client and membership program.
interface IUpdateClientAndMembershipMsgs is IUpdateClientMsgs {
    /// @notice The public value output for the sp1 update client and membership program.
    struct UcAndMembershipOutput {
        /// Update client program output.
        UpdateClientOutput updateClientOutput;
        /// The key-value pairs verified by the membership program in the proposed header.
        IMembershipMsgs.KVPair[] kvPairs;
    }
}
