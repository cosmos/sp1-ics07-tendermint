// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ics07-tendermint/ICS07Tendermint.sol";
import {UpdateClientProgram} from "./ics07-tendermint/UpdateClientProgram.sol";
import {MembershipProgram} from "./ics07-tendermint/MembershipProgram.sol";
import {UpdateClientAndMembershipProgram} from "./ics07-tendermint/UcAndMembershipProgram.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import "forge-std/console.sol";

/// @title SP1ICS07Tendermint
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint {
    /// @notice The verification key for the update client program.
    bytes32 public immutable updateClientProgramVkey;
    /// @notice The verification key for the verify (non)membership program.
    bytes32 public immutable membershipProgramVkey;
    /// @notice The verification key for the update client and membership program.
    bytes32 public immutable updateClientAndMembershipProgramVkey;
    /// @notice The SP1 verifier contract.
    ISP1Verifier public immutable verifier;

    /// @notice The ICS07Tendermint client state
    ICS07Tendermint.ClientState private clientState;
    /// @notice The mapping from height to consensus state keccak256 hashes.
    mapping(uint32 => bytes32) private consensusStateHashes;

    /// Allowed clock drift in seconds
    uint64 public constant ALLOWED_SP1_CLOCK_DRIFT = 3000; // 3000 seconds

    /// @notice The constructor sets the program verification key and the initial client and consensus states.
    /// @param _updateClientProgramVkey The verification key for the update client program.
    /// @param _membershipProgramVkey The verification key for the verify (non)membership program.
    /// @param _updateClientAndMembershipProgramVkey The verification key for the update client and membership program.
    /// @param _verifier The address of the SP1 verifier contract.
    /// @param _clientState The encoded initial client state.
    /// @param _consensusState The encoded initial consensus state.
    constructor(
        bytes32 _updateClientProgramVkey,
        bytes32 _membershipProgramVkey,
        bytes32 _updateClientAndMembershipProgramVkey,
        address _verifier,
        bytes memory _clientState,
        bytes32 _consensusState
    ) {
        updateClientProgramVkey = _updateClientProgramVkey;
        membershipProgramVkey = _membershipProgramVkey;
        updateClientAndMembershipProgramVkey = _updateClientAndMembershipProgramVkey;
        verifier = ISP1Verifier(_verifier);

        clientState = abi.decode(_clientState, (ICS07Tendermint.ClientState));
        consensusStateHashes[
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
        uint32 revisionHeight
    ) public view returns (bytes32) {
        return consensusStateHashes[revisionHeight];
    }

    /// @notice The entrypoint for updating the client.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    function verifyIcs07UpdateClientProof(
        bytes memory proof,
        bytes memory publicValues
    ) public {
        UpdateClientProgram.UpdateClientOutput memory output = abi.decode(
            publicValues,
            (UpdateClientProgram.UpdateClientOutput)
        );

        validateUpdateClientPublicValues(output);

        // TODO: Make sure that other checks have been made in the proof verification
        // such as the consensus state not being outside the trusting period.
        verifier.verifyProof(updateClientProgramVkey, publicValues, proof);

        // adding the new consensus state to the mapping
        clientState.latest_height = output.new_height;
        consensusStateHashes[output.new_height.revision_height] = keccak256(
            abi.encode(output.new_consensus_state)
        );
    }

    /// @notice The entrypoint for verifying membership proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @dev It can validate a subset of the key-value pairs by providing their hashes.
    /// @dev This is useful for batch verification. Zero hashes are skipped.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @param proofHeight The height of the proof.
    /// @param trustedConsensusStateBz The encoded trusted consensus state.
    /// @param kvPairHashes The hashes of the key-value pairs.
    function verifyIcs07MembershipProof(
        bytes memory proof,
        bytes memory publicValues,
        uint32 proofHeight,
        bytes memory trustedConsensusStateBz,
        bytes32[] memory kvPairHashes
    ) public view {
        MembershipProgram.MembershipOutput memory output = abi.decode(
            publicValues,
            (MembershipProgram.MembershipOutput)
        );

        require(
            kvPairHashes.length != 0,
            "SP1ICS07Tendermint: kvPairs length is zero"
        );

        require(
            kvPairHashes.length <= output.kv_pairs.length,
            "SP1ICS07Tendermint: kvPairs length mismatch"
        );

        // loop through the key-value pairs and validate them
        for (uint8 i = 0; i < kvPairHashes.length; i++) {
            bytes32 kvPairHash = kvPairHashes[i];
            if (kvPairHash == 0) {
                // skip the empty hash
                continue;
            }

            require(
                kvPairHash == keccak256(abi.encode(output.kv_pairs[i])),
                "SP1ICS07Tendermint: kvPair hash mismatch"
            );
        }

        validateMembershipOutput(
            output.commitment_root,
            proofHeight,
            trustedConsensusStateBz
        );

        verifier.verifyProof(membershipProgramVkey, publicValues, proof);
    }

    /// @notice The entrypoint for updating the client and membership proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @param kvPairHashes The hashes of the key-value pairs.
    function verifyIcs07UcAndMembershipProof(
        bytes memory proof,
        bytes memory publicValues,
        bytes32[] memory kvPairHashes
    ) public {
        UpdateClientAndMembershipProgram.UcAndMembershipOutput
            memory output = abi.decode(
                publicValues,
                (UpdateClientAndMembershipProgram.UcAndMembershipOutput)
            );

        validateUpdateClientPublicValues(output.update_client_output);
        // adding the new consensus state to the mapping
        clientState.latest_height = output.update_client_output.new_height;
        consensusStateHashes[
            output.update_client_output.new_height.revision_height
        ] = keccak256(
            abi.encode(output.update_client_output.new_consensus_state)
        );

        require(
            kvPairHashes.length != 0,
            "SP1ICS07Tendermint: kvPairs length is zero"
        );

        require(
            kvPairHashes.length <= output.kv_pairs.length,
            "SP1ICS07Tendermint: kvPairs length mismatch"
        );

        // loop through the key-value pairs and validate them
        for (uint8 i = 0; i < kvPairHashes.length; i++) {
            bytes32 kvPairHash = kvPairHashes[i];
            if (kvPairHash == 0) {
                // skip the empty hash
                continue;
            }

            require(
                kvPairHash == keccak256(abi.encode(output.kv_pairs[i])),
                "SP1ICS07Tendermint: kvPair hash mismatch"
            );
        }

        validateMembershipOutput(
            output.update_client_output.new_consensus_state.root,
            output.update_client_output.new_height.revision_height,
            abi.encode(output.update_client_output.new_consensus_state)
        );

        verifier.verifyProof(updateClientProgramVkey, publicValues, proof);
    }

    /// @notice Validates the MembershipOutput public values.
    /// @param outputCommitmentRoot The commitment root of the output.
    /// @param proofHeight The height of the proof.
    /// @param trustedConsensusStateBz The encoded trusted consensus state.
    function validateMembershipOutput(
        bytes32 outputCommitmentRoot,
        uint32 proofHeight,
        bytes memory trustedConsensusStateBz
    ) public view {
        require(
            consensusStateHashes[proofHeight] ==
                keccak256(trustedConsensusStateBz),
            "SP1ICS07Tendermint: trusted consensus state mismatch"
        );

        ICS07Tendermint.ConsensusState memory trustedConsensusState = abi
            .decode(trustedConsensusStateBz, (ICS07Tendermint.ConsensusState));

        require(
            outputCommitmentRoot == trustedConsensusState.root,
            "SP1ICS07Tendermint: invalid commitment root"
        );
    }

    /// @notice Validates the SP1ICS07UpdateClientOutput public values.
    /// @param output The public values.
    function validateUpdateClientPublicValues(
        UpdateClientProgram.UpdateClientOutput memory output
    ) public view {
        require(
            clientState.is_frozen == false,
            "SP1ICS07Tendermint: client is frozen"
        );
        require(
            block.timestamp >= output.env.now,
            "SP1ICS07Tendermint: proof is in the future"
        );
        require(
            block.timestamp - output.env.now <= ALLOWED_SP1_CLOCK_DRIFT,
            "SP1ICS07Tendermint: proof is too old"
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
            consensusStateHashes[output.trusted_height.revision_height] ==
                keccak256(abi.encode(output.trusted_consensus_state)),
            "SP1ICS07Tendermint: trusted consensus state mismatch"
        );
        // TODO: Make sure that we don't need more checks.
    }

    /// @notice A dummy function to generate the ABI for the parameters.
    function abiPublicTypes(
        MembershipProgram.MembershipOutput memory output,
        UpdateClientAndMembershipProgram.UcAndMembershipOutput memory output2
    ) public pure {
        // This is a dummy function to generate the ABI for MembershipOutput
        // so that it can be used in the SP1 verifier contract.
        // The function is not used in the contract.
    }
}
