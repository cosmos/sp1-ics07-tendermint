// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./msgs/IICS07TendermintMsgs.sol";
import { IUpdateClientMsgs } from "./msgs/IUpdateClientMsgs.sol";
import { IMembershipMsgs } from "./msgs/IMembershipMsgs.sol";
import { IUpdateClientAndMembershipMsgs } from "./msgs/IUcAndMembershipMsgs.sol";
import { ISP1Verifier } from "@sp1-contracts/ISP1Verifier.sol";
// import { ILightClient } from "ibc-solidity-interfaces/ILightClient.sol";

/// @title SP1 ICS07 Tendermint Light Client
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client using SP1.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint is IICS07TendermintMsgs, IUpdateClientMsgs, IMembershipMsgs, IUpdateClientAndMembershipMsgs{
    /// @notice The verification key for the update client program.
    bytes32 public immutable UPDATE_CLIENT_PROGRAM_VKEY;
    /// @notice The verification key for the verify (non)membership program.
    bytes32 public immutable MEMBERSHIP_PROGRAM_VKEY;
    /// @notice The verification key for the update client and membership program.
    bytes32 public immutable UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY;
    /// @notice The SP1 verifier contract.
    ISP1Verifier public immutable VERIFIER;

    /// @notice The ICS07Tendermint client state
    ClientState private clientState;
    /// @notice The mapping from height to consensus state keccak256 hashes.
    mapping(uint32 height => bytes32 hash) private consensusStateHashes;

    /// Allowed clock drift in seconds
    uint16 public constant ALLOWED_SP1_CLOCK_DRIFT = 3000; // 3000 seconds

    /// @notice The constructor sets the program verification key and the initial client and consensus states.
    /// @param updateClientProgramVkey The verification key for the update client program.
    /// @param membershipProgramVkey The verification key for the verify (non)membership program.
    /// @param updateClientAndMembershipProgramVkey The verification key for the update client and membership program.
    /// @param verifier The address of the SP1 verifier contract.
    /// @param _clientState The encoded initial client state.
    /// @param _consensusState The encoded initial consensus state.
    constructor(
        bytes32 updateClientProgramVkey,
        bytes32 membershipProgramVkey,
        bytes32 updateClientAndMembershipProgramVkey,
        address verifier,
        bytes memory _clientState,
        bytes32 _consensusState
    ) {
        UPDATE_CLIENT_PROGRAM_VKEY = updateClientProgramVkey;
        MEMBERSHIP_PROGRAM_VKEY = membershipProgramVkey;
        UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY = updateClientAndMembershipProgramVkey;
        VERIFIER = ISP1Verifier(verifier);

        clientState = abi.decode(_clientState, (ClientState));
        consensusStateHashes[clientState.latestHeight.revisionHeight] = _consensusState;
    }

    /// @notice Returns the client state.
    /// @return The client state.
    function getClientState() public view returns (ClientState memory) {
        return clientState;
    }

    /// @notice Returns the consensus state keccak256 hash at the given revision height.
    /// @param revisionHeight The revision height.
    /// @return The consensus state at the given revision height.
    function getConsensusStateHash(uint32 revisionHeight) public view returns (bytes32) {
        return consensusStateHashes[revisionHeight];
    }

    /// @notice The entrypoint for updating the client.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @return The result of the update.
    function updateClient(
        bytes calldata proof,
        bytes calldata publicValues
    )
        public
        returns (UpdateResult)
    {
        UpdateClientOutput memory output =
            abi.decode(publicValues, (UpdateClientOutput));

        validateUpdateClientPublicValues(output);

        // TODO: Make sure that other checks have been made in the proof verification
        VERIFIER.verifyProof(UPDATE_CLIENT_PROGRAM_VKEY, publicValues, proof);

        UpdateResult updateResult = checkUpdateResult(output);
        if (updateResult == UpdateResult.Update) {
            // adding the new consensus state to the mapping
            if (output.newHeight.revisionHeight > clientState.latestHeight.revisionHeight) {
                clientState.latestHeight = output.newHeight;
            }
            consensusStateHashes[output.newHeight.revisionHeight] = keccak256(abi.encode(output.newConsensusState));
        } else if (updateResult == UpdateResult.Misbehaviour) {
            clientState.isFrozen = true;
        } // else: NoOp

        return updateResult;
    }

    /// @notice The entrypoint for batch verifying (non)membership proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @dev It can validate a subset of the key-value pairs by providing their hashes.
    /// @dev This is useful for batch verification. Zero hashes are skipped.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @param proofHeight The height of the proof.
    /// @param trustedConsensusStateBz The encoded trusted consensus state.
    /// @param kvPairHashes The hashes of the key-value pairs.
    function batchVerifyMembership(
        bytes calldata proof,
        bytes calldata publicValues,
        uint32 proofHeight,
        bytes calldata trustedConsensusStateBz,
        bytes32[] calldata kvPairHashes
    )
        public
        view
    {
        MembershipOutput memory output =
            abi.decode(publicValues, (MembershipOutput));

        require(kvPairHashes.length != 0, "SP1ICS07Tendermint: kvPairs length is zero");

        require(kvPairHashes.length <= output.kvPairs.length, "SP1ICS07Tendermint: kvPairs length mismatch");

        // loop through the key-value pairs and validate them
        for (uint8 i = 0; i < kvPairHashes.length; i++) {
            bytes32 kvPairHash = kvPairHashes[i];
            if (kvPairHash == 0) {
                // skip the empty hash
                continue;
            }

            require(kvPairHash == keccak256(abi.encode(output.kvPairs[i])), "SP1ICS07Tendermint: kvPair hash mismatch");
        }

        validateMembershipOutput(output.commitmentRoot, proofHeight, trustedConsensusStateBz);

        VERIFIER.verifyProof(MEMBERSHIP_PROGRAM_VKEY, publicValues, proof);
    }

    /// @notice The entrypoint for updating the client and membership proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @param kvPairHashes The hashes of the key-value pairs.
    /// @return The result of the update.
    function updateClientAndBatchVerifyMembership(
        bytes calldata proof,
        bytes calldata publicValues,
        bytes32[] calldata kvPairHashes
    )
        public
        returns (UpdateResult)
    {
        UcAndMembershipOutput memory output =
            abi.decode(publicValues, (UcAndMembershipOutput));

        validateUpdateClientPublicValues(output.updateClientOutput);

        VERIFIER.verifyProof(UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY, publicValues, proof);

        UpdateResult updateResult = checkUpdateResult(output.updateClientOutput);
        if (updateResult == UpdateResult.Update) {
            // adding the new consensus state to the mapping
            clientState.latestHeight = output.updateClientOutput.newHeight;
            consensusStateHashes[output.updateClientOutput.newHeight.revisionHeight] =
                keccak256(abi.encode(output.updateClientOutput.newConsensusState));
        } else if (updateResult == UpdateResult.Misbehaviour) {
            clientState.isFrozen = true;
            return UpdateResult.Misbehaviour;
        } // else: NoOp

        require(kvPairHashes.length != 0, "SP1ICS07Tendermint: kvPairs length is zero");

        require(kvPairHashes.length <= output.kvPairs.length, "SP1ICS07Tendermint: kvPairs length mismatch");

        // loop through the key-value pairs and validate them
        for (uint8 i = 0; i < kvPairHashes.length; i++) {
            bytes32 kvPairHash = kvPairHashes[i];
            if (kvPairHash == 0) {
                // skip the empty hash
                continue;
            }

            require(kvPairHash == keccak256(abi.encode(output.kvPairs[i])), "SP1ICS07Tendermint: kvPair hash mismatch");
        }

        validateMembershipOutput(
            output.updateClientOutput.newConsensusState.root,
            output.updateClientOutput.newHeight.revisionHeight,
            abi.encode(output.updateClientOutput.newConsensusState)
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
    )
        private
        view
    {
        require(clientState.isFrozen == false, "SP1ICS07Tendermint: client is frozen");
        require(
            consensusStateHashes[proofHeight] == keccak256(trustedConsensusStateBz),
            "SP1ICS07Tendermint: trusted consensus state mismatch"
        );

        ConsensusState memory trustedConsensusState =
            abi.decode(trustedConsensusStateBz, (ConsensusState));

        require(outputCommitmentRoot == trustedConsensusState.root, "SP1ICS07Tendermint: invalid commitment root");
    }

    /// @notice Validates the SP1ICS07UpdateClientOutput public values.
    /// @param output The public values.
    function validateUpdateClientPublicValues(UpdateClientOutput memory output) private view {
        require(clientState.isFrozen == false, "SP1ICS07Tendermint: client is frozen");
        require(block.timestamp >= output.env.now, "SP1ICS07Tendermint: proof is in the future");
        require(block.timestamp - output.env.now <= ALLOWED_SP1_CLOCK_DRIFT, "SP1ICS07Tendermint: proof is too old");
        require(
            keccak256(bytes(output.env.chainId)) == keccak256(bytes(clientState.chainId)),
            "SP1ICS07Tendermint: chain ID mismatch"
        );
        require(
            output.env.trustThreshold.numerator == clientState.trustLevel.numerator
                && output.env.trustThreshold.denominator == clientState.trustLevel.denominator,
            "SP1ICS07Tendermint: trust threshold mismatch"
        );
        require(output.env.trustingPeriod == clientState.trustingPeriod, "SP1ICS07Tendermint: trusting period mismatch");
        require(
            output.env.trustingPeriod <= clientState.unbondingPeriod,
            "SP1ICS07Tendermint: trusting period longer than unbonding period"
        );
        require(
            consensusStateHashes[output.trustedHeight.revisionHeight]
                == keccak256(abi.encode(output.trustedConsensusState)),
            "SP1ICS07Tendermint: trusted consensus state mismatch"
        );
        // TODO: Make sure that we don't need more checks.
    }

    /// @notice Checks for basic misbehaviour.
    /// @dev This function checks if the consensus state at the new height is different than the one in the mapping.
    /// @dev This function does not check timestamp misbehaviour (a niche case).
    /// @param output The public values of the update client program.
    function checkUpdateResult(UpdateClientOutput memory output)
        private
        view
        returns (UpdateResult)
    {
        bytes32 consensusStateHash = consensusStateHashes[output.newHeight.revisionHeight];
        if (consensusStateHash == bytes32(0)) {
            // No consensus state at the new height, so no misbehaviour
            return UpdateResult.Update;
        }
        if (consensusStateHash != keccak256(abi.encode(output.newConsensusState))) {
            // The consensus state at the new height is different than the one in the mapping
            return UpdateResult.Misbehaviour;
        } else {
            // The consensus state at the new height is the same as the one in the mapping
            return UpdateResult.NoOp;
        }
    }

    /// @notice A dummy function to generate the ABI for the parameters.
    function abiPublicTypes(
        MembershipOutput memory output,
        UcAndMembershipOutput memory output2
    )
        public
        pure
    // solhint-disable-next-line no-empty-blocks
    {
        // This is a dummy function to generate the ABI for MembershipOutput
        // so that it can be used in the SP1 verifier contract.
        // The function is not used in the contract.
    }
}
