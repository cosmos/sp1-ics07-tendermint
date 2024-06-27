// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ics07-tendermint/ICS07Tendermint.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import "forge-std/console.sol";

/// @title SP1ICS07Tendermint
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint {
    /// @notice The verification key for the program.
    bytes32 public ics07UpdateClientProgramVkey;
    /// @notice The SP1 verifier contract.
    ISP1Verifier public verifier;

    /// @notice The ICS07Tendermint client state
    ICS07Tendermint.ClientState public clientState;
    /// @notice The mapping from height to consensus state keccak256 hash.
    mapping(uint64 => bytes32) public consensusStates;

    /// Allowed clock drift in nanoseconds
    uint64 public constant ALLOWED_SP1_CLOCK_DRIFT = 30_000_000_000_000; // 30000 seconds

    /// @notice The public value output for the sp1 program.
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

    /// @notice The environment output for the sp1 program.
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

    /// @notice The constructor sets the program verification key and the initial client and consensus states.
    /// @param _ics07ProgramVkey The verification key for the program.
    /// @param _verifier The address of the SP1 verifier contract.
    /// @param _clientState The encoded initial client state.
    /// @param _consensusState The encoded initial consensus state.
    constructor(
        bytes32 _ics07ProgramVkey,
        address _verifier,
        bytes memory _clientState,
        bytes32 _consensusState
    ) {
        ics07UpdateClientProgramVkey = _ics07ProgramVkey;
        verifier = ISP1Verifier(_verifier);

        clientState = abi.decode(_clientState, (ICS07Tendermint.ClientState));
        consensusStates[
            clientState.latest_height.revision_height
        ] = _consensusState;
    }

    /// @notice Returns the client state.
    /// @return The client state.
    function getClientState()
        public
        view
        returns (ICS07Tendermint.ClientState memory)
    {
        return clientState;
    }

    /// @notice Returns the consensus state at the given revision height.
    /// @param revisionHeight The revision height.
    /// @return The consensus state at the given revision height.
    function getConsensusState(
        uint64 revisionHeight
    ) public view returns (bytes32) {
        return consensusStates[revisionHeight];
    }

    /// @notice The entrypoint for verifying the proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
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

        validatePublicValues(output);

        // TODO: Make sure that other checks have been made in the proof verification
        // such as the consensus state not being outside the trusting period.
        verifier.verifyProof(ics07UpdateClientProgramVkey, publicValues, proof);

        // adding the new consensus state to the mapping
        clientState.latest_height = output.new_height;
        consensusStates[output.new_height.revision_height] = keccak256(
            abi.encode(output.new_consensus_state)
        );
    }

    /// @notice Validates the SP1ICS07TendermintOutput public values.
    /// @param output The public values.
    function validatePublicValues(
        SP1ICS07TendermintOutput memory output
    ) public view {
        require(
            clientState.is_frozen == false,
            "SP1ICS07Tendermint: client is frozen"
        );
        // TODO: Make sure this timestamp check is correct
        require(
            block.timestamp * 1e9 <= output.env.now + ALLOWED_SP1_CLOCK_DRIFT,
            "SP1ICS07Tendermint: invalid timestamp"
        );
        require(
            keccak256(bytes(output.env.chain_id)) ==
                keccak256(bytes(clientState.chain_id)),
            "SP1ICS07Tendermint: chain ID mismatch"
        );
        require(
            output.env.trust_threshold.numerator ==
                clientState.trust_level.numerator &&
                output.env.trust_threshold.denominator ==
                clientState.trust_level.denominator,
            "SP1ICS07Tendermint: trust threshold mismatch"
        );
        require(
            output.env.trusting_period == clientState.trusting_period,
            "SP1ICS07Tendermint: trusting period mismatch"
        );
        require(
            output.env.trusting_period == clientState.unbonding_period,
            "SP1ICS07Tendermint: unbonding period mismatch"
        );
        require(
            consensusStates[output.trusted_height.revision_height] ==
                keccak256(abi.encode(output.trusted_consensus_state)),
            "SP1ICS07Tendermint: trusted consensus state mismatch"
        );
        // TODO: Make sure that we don't need more checks.
    }
}
