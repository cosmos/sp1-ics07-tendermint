// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ILightClientMsgs } from "solidity-ibc/msgs/ILightClientMsgs.sol";

/// @title Membership Program Messages
/// @author srdtrk
/// @notice Defines shared types for the verify (non)membership program.
interface IMembershipMsgs is ILightClientMsgs {
    /// @notice The public value output for the sp1 verify (non)membership program.
    struct MembershipOutput {
        bytes32 commitmentRoot;
        KVPair[] kvPairs;
    }
}
