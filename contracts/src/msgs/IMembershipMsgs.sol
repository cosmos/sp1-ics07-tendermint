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
        /// The app hash of the header.
        bytes32 commitmentRoot;
        /// The key-value pairs verified by the program.
        KVPair[] kvPairs;
    }

    /// @notice The membership proof for the sp1 verify (non)membership program.
    struct SP1MembershipProof {
        /// The sp1 proof for the membership program.
        SP1Proof sp1Proof;
        /// The trusted consensus state that the proof is based on.
        IICS07TendermintMsgs.ConsensusState trustedConsensusState;
    }

    /// @notice The membership proof for the sp1 verify (non)membership and update client program.
    struct SP1MembershipAndUpdateClientProof {
        /// The sp1 proof for the membership and update client program.
        SP1Proof sp1Proof;
    }

    /// @notice The type of the membership proof.
    enum MembershipProofType {
        /// The proof is for the verify membership program.
        SP1MembershipProof,
        /// The proof is for the verify membership and update client program.
        SP1MembershipAndUpdateClientProof
    }

    /// @notice The membership proof that can be submitted to the SP1Verifier contract.
    struct MembershipProof {
        /// The type of the membership proof.
        MembershipProofType proofType;
        /// The membership proof.
        bytes proof;
    }
}
