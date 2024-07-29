// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

/// @title SP1 Messages
interface ISP1Msgs {
    /// @notice The SP1 proof that can be submitted to the SP1Verifier contract.
    struct SP1Proof {
        /// The verification key for the program.
        bytes32 vKey;
        /// The public values for the program.
        bytes publicValues;
        /// The proof for the program.
        bytes proof;
    }
}
