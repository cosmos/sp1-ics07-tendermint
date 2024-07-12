// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ics07-tendermint/ICS07Tendermint.sol";
import {UpdateClientProgram} from "./ics07-tendermint/UpdateClientProgram.sol";
import {MembershipProgram} from "./ics07-tendermint/MembershipProgram.sol";
import {UpdateClientAndMembershipProgram} from "./ics07-tendermint/UcAndMembershipProgram.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import {ISP1ICS07Tendermint} from "./ISP1ICS07Tendermint.sol";
import "forge-std/console.sol";

/// @title SP1 ICS07 Tendermint Light Client
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client using SP1.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint is ISP1ICS07Tendermint {
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

    /// @notice Returns the consensus state keccak256 hash at the given revision height.
    /// @param revisionHeight The revision height.
    /// @return The consensus state at the given revision height.
    function getConsensusStateHash(
        uint32 revisionHeight
    ) public view returns (bytes32) {
        return consensusStateHashes[revisionHeight];
    }

    /// @notice The entrypoint for updating the client.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    function updateClient(
        bytes calldata proof,
        bytes calldata publicValues
    ) public returns (UpdateClientProgram.UpdateResult) {
        UpdateClientProgram.UpdateClientOutput memory output = abi.decode(
            publicValues,
            (UpdateClientProgram.UpdateClientOutput)
        );

        validateUpdateClientPublicValues(output);

        // TODO: Make sure that other checks have been made in the proof verification
        verifier.verifyProof(updateClientProgramVkey, publicValues, proof);

        UpdateClientProgram.UpdateResult updateResult = checkUpdateResult(
            output
        );
        if (updateResult == UpdateClientProgram.UpdateResult.Update) {
            // adding the new consensus state to the mapping
            if (
                output.new_height.revision_height >
                clientState.latest_height.revision_height
            ) {
                clientState.latest_height = output.new_height;
            }
            consensusStateHashes[output.new_height.revision_height] = keccak256(
                abi.encode(output.new_consensus_state)
            );
        } else if (
            updateResult == UpdateClientProgram.UpdateResult.Misbehaviour
        ) {
            clientState.is_frozen = true;
        } // else: NoOp

        return updateResult;
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
        bytes calldata proof,
        bytes calldata publicValues,
        uint32 proofHeight,
        bytes calldata trustedConsensusStateBz,
        bytes32[] calldata kvPairHashes
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
        bytes calldata proof,
        bytes calldata publicValues,
        bytes32[] calldata kvPairHashes
    ) public returns (UpdateClientProgram.UpdateResult) {
        UpdateClientAndMembershipProgram.UcAndMembershipOutput
            memory output = abi.decode(
                publicValues,
                (UpdateClientAndMembershipProgram.UcAndMembershipOutput)
            );

        validateUpdateClientPublicValues(output.update_client_output);

        verifier.verifyProof(updateClientProgramVkey, publicValues, proof);

        UpdateClientProgram.UpdateResult updateResult = checkUpdateResult(
            output.update_client_output
        );
        if (updateResult == UpdateClientProgram.UpdateResult.Update) {
            // adding the new consensus state to the mapping
            clientState.latest_height = output.update_client_output.new_height;
            consensusStateHashes[
                output.update_client_output.new_height.revision_height
            ] = keccak256(
                abi.encode(output.update_client_output.new_consensus_state)
            );
        } else if (
            updateResult == UpdateClientProgram.UpdateResult.Misbehaviour
        ) {
            clientState.is_frozen = true;
            return UpdateClientProgram.UpdateResult.Misbehaviour;
        } // else: NoOp

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

        return updateResult;
    }

    /// @notice Validates the MembershipOutput public values.
    /// @param outputCommitmentRoot The commitment root of the output.
    /// @param proofHeight The height of the proof.
    /// @param trustedConsensusStateBz The encoded trusted consensus state.
    function validateMembershipOutput(
        bytes32 outputCommitmentRoot,
        uint32 proofHeight,
        bytes memory trustedConsensusStateBz
    ) private view {
        require(
            clientState.is_frozen == false,
            "SP1ICS07Tendermint: client is frozen"
        );
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
    ) private view {
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

    /// @notice Checks for basic misbehaviour.
    /// @dev This function checks if the consensus state at the new height is different than the one in the mapping.
    /// @dev This function does not check timestamp misbehaviour (a niche case).
    /// @param output The public values of the update client program.
    function checkUpdateResult(
        UpdateClientProgram.UpdateClientOutput memory output
    ) public view returns (UpdateClientProgram.UpdateResult) {
        bytes32 consensusStateHash = consensusStateHashes[
            output.new_height.revision_height
        ];
        if (consensusStateHash == bytes32(0)) {
            // No consensus state at the new height, so no misbehaviour
            return UpdateClientProgram.UpdateResult.Update;
        }
        if (
            consensusStateHash !=
            keccak256(abi.encode(output.new_consensus_state))
        ) {
            // The consensus state at the new height is different than the one in the mapping
            return UpdateClientProgram.UpdateResult.Misbehaviour;
        } else {
            // The consensus state at the new height is the same as the one in the mapping
            return UpdateClientProgram.UpdateResult.NoOp;
        }
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
