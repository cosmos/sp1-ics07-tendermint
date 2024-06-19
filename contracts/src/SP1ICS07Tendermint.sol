// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "ibc-lite-shared/ics07-tendermint/ICS07Tendermint.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @title SP1ICS07Tendermint
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client.
contract SP1ICS07Tendermint {
    /// @notice The verification key for the program.
    bytes32 public ics07ProgramVkey;
    // @notice The SP1 verifier contract.
    ISP1Verifier public verifier;

    // @notice The ICS07Tendermint client state
    ICS07Tendermint.ClientState public clientState;
    // @notice The mapping from height to consensus state
    mapping(uint64 => ICS07Tendermint.ConsensusState) public consensusStates;

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
