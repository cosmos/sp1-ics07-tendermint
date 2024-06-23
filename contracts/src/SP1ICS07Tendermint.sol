// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "ibc-lite-shared/ics07-tendermint/ICS07Tendermint.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @title SP1ICS07Tendermint
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client.
contract SP1ICS07Tendermint {
    /// @notice The verification key for the program.
    bytes32 public ics07UpdateClientProgramVkey;
    // @notice The SP1 verifier contract.
    ISP1Verifier public verifier;

    // @notice The ICS07Tendermint client state
    ICS07Tendermint.ClientState public clientState;
    // @notice The mapping from height to consensus state
    mapping(uint64 => ICS07Tendermint.ConsensusState) public consensusStates;

    /// Allowed clock drift in nanoseconds
    uint64 public constant ALLOWED_SP1_CLOCK_DRIFT = 6_000_000_000_000; // 6000 seconds

    // @notice The constructor sets the program verification key.
    // @param _ics07ProgramVkey The verification key for the program.
    // @param _verifier The address of the SP1 verifier contract.
    constructor(
        bytes32 _ics07ProgramVkey,
        address _verifier,
        bytes memory _clientState,
        bytes memory _consensusState
    ) {
        ics07UpdateClientProgramVkey = _ics07ProgramVkey;
        verifier = ISP1Verifier(_verifier);

        clientState = abi.decode(_clientState, (ICS07Tendermint.ClientState));
        ICS07Tendermint.ConsensusState memory consensusState = abi.decode(
            _consensusState,
            (ICS07Tendermint.ConsensusState)
        );
        consensusStates[
            clientState.latest_height.revision_height
        ] = consensusState;
    }

    /// @notice The entrypoint for verifying the proof.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    function verifyIcs07UpdateClientProof(
        bytes memory proof,
        bytes memory publicValues
    ) public {
        SP1ICS07TendermintOutput memory output = abi.decode(
            publicValues,
            (SP1ICS07TendermintOutput)
        );

        require(
            block.timestamp * 1e9 <= output.env.now + ALLOWED_SP1_CLOCK_DRIFT,
            "SP1ICS07Tendermint: invalid timestamp"
        );

        // TODO: verify that the client state and the saved consensus state match the public values.
        // More checks need to be made here get the trusted consensus clientState and etc

        verifier.verifyProof(ics07UpdateClientProgramVkey, publicValues, proof);

        // adding the new consensus state to the mapping
        clientState.latest_height = output.new_height;
        consensusStates[output.new_consensus_state.timestamp] = output
            .new_consensus_state;
    }

    /// The public value output for the sp1 program.
    struct SP1ICS07TendermintOutput {
        /// The trusted consensus state.
        ICS07Tendermint.ConsensusState trusted_consensus_state;
        /// The new consensus state with the verified header.
        ICS07Tendermint.ConsensusState new_consensus_state;
        /// The validation environment.
        Env env;
        /// trusted height
        ICS07Tendermint.Height trusted_height;
        /// new height
        ICS07Tendermint.Height new_height;
    }

    /// The environment output for the sp1 program.
    struct Env {
        /// The chain ID of the chain that the client is tracking.
        string chain_id;
        /// Fraction of validator overlap needed to update header
        ICS07Tendermint.TrustThreshold trust_threshold;
        /// Duration of the period since the `LatestTimestamp` during which the
        /// submitted headers are valid for upgrade
        uint64 trusting_period;
        /// Timestamp in nanoseconds
        uint64 now;
    }
}
