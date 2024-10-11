// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Ics23, UnionIcs23 } from "union-lib/ICS23.sol";

/// @title UnionMembership
/// @notice A library for verifying membership and non-membership proofs powered by Union's ICS23 library.
library UnionMembership {
    /// @notice A non-membership proof for a key.
    /// @dev The proof consists of an ICS23 NonExistenceProof and an ICS23 ExistenceProof.
    /// @param nonExistenceProof The non-existence proof.
    /// @param existenceProof The existence proof.
    struct UnionNonMembershipProof {
        UnionIcs23.NonExistenceProof nonExistenceProof;
        UnionIcs23.ExistenceProof existenceProof;
    }

    /// @notice A membership proof for a key-value pair.
    /// @dev The proof consists of two ICS23 ExistenceProofs.
    /// @param membershipProofs The membership proofs.
    struct UnionMembershipProof {
        UnionIcs23.ExistenceProof[2] membershipProofs;
    }

    /// @notice Verifies the membership or non-membership of a key-value pair.
    /// @dev If the value is empty, the function verifies non-membership.
    /// @param proof The membership proof.
    /// @param key The key of the key-value pair.
    /// @param value The value of the key-value pair.
    /// @return True if the proof is verified, false otherwise.
    function verify(
        bytes32 root,
        bytes calldata proof,
        bytes calldata prefix,
        bytes calldata key,
        bytes calldata value
    )
        public
        pure
        returns (bool)
    {
        if (value.length == 0) {
            UnionNonMembershipProof calldata nmProof;
            assembly {
                nmProof := proof.offset
            } // TODO: make sure this works
            return Ics23.verifyChainedNonMembership(
                nmProof.nonExistenceProof, nmProof.existenceProof, root, prefix, key
            ) == Ics23.VerifyChainedNonMembershipError.None;
        } else {
            UnionMembershipProof calldata mProof;
            assembly {
                mProof := proof.offset
            }
            return Ics23.verifyChainedMembership(mProof.membershipProofs, root, prefix, key, value)
                == Ics23.VerifyChainedMembershipError.None;
        }
    }
}
