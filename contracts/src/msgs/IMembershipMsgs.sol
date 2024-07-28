// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ISP1Msgs } from "./ISP1Msgs.sol";
import { IICS07TendermintMsgs } from "./IICS07TendermintMsgs.sol";

/// @title Membership Program Messages
/// @author srdtrk
/// @notice Defines shared types for the verify (non)membership program.
interface IMembershipMsgs is ISP1Msgs {
    /// @notice The key-value pair used in the verify (non)membership program.
    struct KVPair {
        /// The path of the value in the key-value store.
        bytes path;
        /// The value of the key-value pair.
        bytes value;
    }

    /// @notice The public value output for the sp1 verify (non)membership program.
    struct MembershipOutput {
        bytes32 commitmentRoot;
        KVPair[] kvPairs;
    }

    /// @notice The membership proof that can be submitted to the SP1Verifier contract.
    struct MembershipProof {
        /// The sp1 proof for the membership program.
        SP1Proof sp1Proof;
        /// The trusted consensus state that the proof is based on.
        IICS07TendermintMsgs.ConsensusState trustedConsensusState;
    }
}
