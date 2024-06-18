// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @title Fibonacci.
/// @author Succinct Labs
/// @notice This contract implements a simple example of verifying the proof of a computing a
///         fibonacci number.
contract SP1ICS07Tendermint {
    /// @notice The verification key for the fibonacci program.
    bytes32 public ics07ProgramVkey;
    // @notice The SP1 verifier contract.
    ISP1Verifier public verifier;

    // @notice The constructor sets the program verification key.
    // @param _ics07ProgramVkey The verification key for the program.
    // @param _verifier The address of the SP1 verifier contract.
    constructor(bytes32 _ics07ProgramVkey, address _verifier) {
        ics07ProgramVkey = _ics07ProgramVkey;
        verifier = ISP1Verifier(_verifier);
    }

    /// @notice The entrypoint for verifying the proof.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    // TODO: modify the return tyoe and the public values to match the actual program.
    function verifyIcs07Proof(
        bytes memory proof,
        bytes memory publicValues
    ) public view returns (uint32, uint32, uint32) {
        verifier.verifyProof(ics07ProgramVkey, publicValues, proof);
        (uint32 n, uint32 a, uint32 b) = abi.decode(
            publicValues,
            (uint32, uint32, uint32)
        );
        return (n, a, b);
    }
}
