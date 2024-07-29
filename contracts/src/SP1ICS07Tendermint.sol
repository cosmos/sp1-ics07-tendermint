// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./msgs/IICS07TendermintMsgs.sol";
import { IUpdateClientMsgs } from "./msgs/IUpdateClientMsgs.sol";
import { IMembershipMsgs } from "./msgs/IMembershipMsgs.sol";
import { IUpdateClientAndMembershipMsgs } from "./msgs/IUcAndMembershipMsgs.sol";
import { ISP1Verifier } from "@sp1-contracts/ISP1Verifier.sol";
import { ISP1ICS07TendermintErrors } from "./errors/ISP1ICS07TendermintErrors.sol";
import { ILightClientMsgs } from "solidity-ibc/msgs/ILightClientMsgs.sol";
// import { ILightClient } from "ibc-solidity-interfaces/ILightClient.sol";

/// @title SP1 ICS07 Tendermint Light Client
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client using SP1.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint is
    IICS07TendermintMsgs,
    IUpdateClientMsgs,
    IMembershipMsgs,
    IUpdateClientAndMembershipMsgs,
    ISP1ICS07TendermintErrors,
    ILightClientMsgs
{
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
        bytes32 hash = consensusStateHashes[revisionHeight];
        if (hash == 0) {
            revert ConsensusStateNotFound();
        }
        return hash;
    }

    /// @notice The entrypoint for updating the client.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param updateMsg The encoded update message.
    /// @return The result of the update.
    function updateClient(bytes calldata updateMsg) public returns (UpdateResult) {
        MsgUpdateClient memory msgUpdateClient = abi.decode(updateMsg, (MsgUpdateClient));
        if (msgUpdateClient.sp1Proof.vKey != UPDATE_CLIENT_PROGRAM_VKEY) {
            revert VerificationKeyMismatch(UPDATE_CLIENT_PROGRAM_VKEY, msgUpdateClient.sp1Proof.vKey);
        }

        UpdateClientOutput memory output = abi.decode(msgUpdateClient.sp1Proof.publicValues, (UpdateClientOutput));

        validateUpdateClientPublicValues(output);

        UpdateResult updateResult = checkUpdateResult(output);
        if (updateResult == UpdateResult.Update) {
            // adding the new consensus state to the mapping
            if (output.newHeight.revisionHeight > clientState.latestHeight.revisionHeight) {
                clientState.latestHeight = output.newHeight;
            }
            consensusStateHashes[output.newHeight.revisionHeight] = keccak256(abi.encode(output.newConsensusState));
        } else if (updateResult == UpdateResult.Misbehaviour) {
            clientState.isFrozen = true;
        } else if (updateResult == UpdateResult.NoOp) {
            return UpdateResult.NoOp;
        }

        verifySP1Proof(msgUpdateClient.sp1Proof);

        return updateResult;
    }

    /// @notice The entrypoint for verifying (non)membership proof.
    /// @param msgMembership The membership message.
    /// @return timestamp The timestamp of the trusted consensus state.
    function membership(MsgMembership calldata msgMembership) public returns (uint256 timestamp) {
        MembershipProof memory membershipProof = abi.decode(msgMembership.proof, (MembershipProof));
        if (membershipProof.proofType == MembershipProofType.SP1MembershipProof) {
            return handleSP1MembershipProof(
                msgMembership.proofHeight, membershipProof.proof, msgMembership.path, msgMembership.value
            );
        } else if (membershipProof.proofType == MembershipProofType.SP1MembershipAndUpdateClientProof) {
            return handleSP1UpdateClientAndMembership(msgMembership.proofHeight, membershipProof.proof, msgMembership.path, msgMembership.value);
        } else {
            revert UnknownMembershipProofType(uint8(membershipProof.proofType));
        }
    }

    function handleSP1MembershipProof(
        Height memory proofHeight,
        bytes memory proofBytes,
        bytes memory kvPath,
        bytes memory kvValue
    )
        private
        view
        returns (uint256)
    {
        if (proofHeight.revisionNumber != clientState.latestHeight.revisionNumber) {
            revert ProofHeightMismatch(proofHeight.revisionNumber, proofHeight.revisionHeight, clientState.latestHeight.revisionNumber, clientState.latestHeight.revisionHeight);
        }

        SP1MembershipProof memory proof = abi.decode(proofBytes, (SP1MembershipProof));
        if (proof.sp1Proof.vKey != MEMBERSHIP_PROGRAM_VKEY) {
            revert VerificationKeyMismatch(MEMBERSHIP_PROGRAM_VKEY, proof.sp1Proof.vKey);
        }

        MembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (MembershipOutput));
        if (output.kvPairs.length == 0 || output.kvPairs.length > 256) {
            revert LengthIsOutOfRange(output.kvPairs.length, 1, 256);
        }

        // loop through the key-value pairs and validate them
        bool found = false;
        for (uint8 i = 0; i < output.kvPairs.length; i++) {
            bytes memory path = output.kvPairs[i].path;
            if (keccak256(path) != keccak256(kvPath)) {
                continue;
            }

            bytes memory value = output.kvPairs[i].value;
            if (keccak256(value) != keccak256(kvValue)) {
                revert MembershipProofValueMismatch(kvValue, value);
            }

            found = true;
            break;
        }
        if (!found) {
            revert MembershipProofKeyNotFound(kvPath);
        }

        validateMembershipOutput(output.commitmentRoot, proofHeight.revisionHeight, proof.trustedConsensusState);

        verifySP1Proof(proof.sp1Proof);

        return proof.trustedConsensusState.timestamp;
    }

    /// @notice The entrypoint for updating the client and membership proof.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proofHeight The height of the proof.
    /// @param proofBytes The encoded proof.
    /// @param kvPath The path of the key-value pair.
    /// @param kvValue The value of the key-value pair.
    /// @return The timestamp of the new consensus state.
    function handleSP1UpdateClientAndMembership(
        Height memory proofHeight,
        bytes memory proofBytes,
        bytes memory kvPath,
        bytes memory kvValue
    )
        private
        returns (uint256)
    {
        SP1MembershipAndUpdateClientProof memory proof = abi.decode(proofBytes, (SP1MembershipAndUpdateClientProof));
        if (proof.sp1Proof.vKey != UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY) {
            revert VerificationKeyMismatch(UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY, proof.sp1Proof.vKey);
        }

        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        if (output.kvPairs.length == 0 || output.kvPairs.length > 256) {
            revert LengthIsOutOfRange(output.kvPairs.length, 1, 256);
        }

        if (proofHeight.revisionHeight != output.updateClientOutput.newHeight.revisionHeight || proofHeight.revisionNumber != output.updateClientOutput.newHeight.revisionNumber) {
            revert ProofHeightMismatch(proofHeight.revisionNumber, proofHeight.revisionHeight, output.updateClientOutput.newHeight.revisionNumber, output.updateClientOutput.newHeight.revisionHeight);
        }


        validateUpdateClientPublicValues(output.updateClientOutput);

        verifySP1Proof(proof.sp1Proof);

        UpdateResult updateResult = checkUpdateResult(output.updateClientOutput);
        if (updateResult == UpdateResult.Update) {
            // adding the new consensus state to the mapping
            if (proofHeight.revisionHeight > clientState.latestHeight.revisionHeight) {
                clientState.latestHeight = output.updateClientOutput.newHeight;
            }
            consensusStateHashes[proofHeight.revisionHeight] =
                keccak256(abi.encode(output.updateClientOutput.newConsensusState));
        } else if (updateResult == UpdateResult.Misbehaviour) {
            clientState.isFrozen = true;
            revert CannotHandleMisbehavior();
        } // else: NoOp

        // loop through the key-value pairs and validate them
        bool found = false;
        for (uint8 i = 0; i < output.kvPairs.length; i++) {
            bytes memory path = output.kvPairs[i].path;
            if (keccak256(path) != keccak256(kvPath)) {
                continue;
            }

            bytes memory value = output.kvPairs[i].value;
            if (keccak256(value) != keccak256(kvValue)) {
                revert MembershipProofValueMismatch(kvValue, value);
            }

            found = true;
            break;
        }
        if (!found) {
            revert MembershipProofKeyNotFound(kvPath);
        }

        validateMembershipOutput(
            output.updateClientOutput.newConsensusState.root,
            output.updateClientOutput.newHeight.revisionHeight,
            output.updateClientOutput.newConsensusState
        );

        return output.updateClientOutput.newConsensusState.timestamp;
    }

    /// @notice Validates the MembershipOutput public values.
    /// @param outputCommitmentRoot The commitment root of the output.
    /// @param proofHeight The height of the proof.
    /// @param trustedConsensusState The trusted consensus state.
    function validateMembershipOutput(
        bytes32 outputCommitmentRoot,
        uint32 proofHeight,
        ConsensusState memory trustedConsensusState
    )
        private
        view
    {
        if (clientState.isFrozen) {
            revert FrozenClientState();
        }
        if (outputCommitmentRoot != trustedConsensusState.root) {
            revert ConsensusStateRootMismatch(trustedConsensusState.root, outputCommitmentRoot);
        }
        bytes32 trustedConsensusStateHash = keccak256(abi.encode(trustedConsensusState));
        if (consensusStateHashes[proofHeight] != trustedConsensusStateHash) {
            revert ConsensusStateHashMismatch(trustedConsensusStateHash, consensusStateHashes[proofHeight]);
        }
    }

    /// @notice Validates the SP1ICS07UpdateClientOutput public values.
    /// @param output The public values.
    function validateUpdateClientPublicValues(UpdateClientOutput memory output) private view {
        if (clientState.isFrozen) {
            revert FrozenClientState();
        }
        if (output.env.now > block.timestamp) {
            revert ProofIsInTheFuture(block.timestamp, output.env.now);
        }
        if (block.timestamp - output.env.now > ALLOWED_SP1_CLOCK_DRIFT) {
            revert ProofIsTooOld(block.timestamp, output.env.now);
        }
        if (keccak256(bytes(output.env.chainId)) != keccak256(bytes(clientState.chainId))) {
            revert ChainIdMismatch(clientState.chainId, output.env.chainId);
        }
        if (
            output.env.trustThreshold.numerator != clientState.trustLevel.numerator
                || output.env.trustThreshold.denominator != clientState.trustLevel.denominator
        ) {
            revert TrustThresholdMismatch(
                clientState.trustLevel.numerator,
                clientState.trustLevel.denominator,
                output.env.trustThreshold.numerator,
                output.env.trustThreshold.denominator
            );
        }
        if (output.env.trustingPeriod != clientState.trustingPeriod) {
            revert TrustingPeriodMismatch(clientState.trustingPeriod, output.env.trustingPeriod);
        }
        if (output.env.trustingPeriod > clientState.unbondingPeriod) {
            revert TrustingPeriodTooLong(output.env.trustingPeriod, clientState.unbondingPeriod);
        }

        bytes32 outputConsensusStateHash = keccak256(abi.encode(output.trustedConsensusState));
        bytes32 trustedConsensusStateHash = getConsensusStateHash(output.trustedHeight.revisionHeight);
        if (outputConsensusStateHash != trustedConsensusStateHash) {
            revert ConsensusStateHashMismatch(trustedConsensusStateHash, outputConsensusStateHash);
        }
    }

    /// @notice Checks for basic misbehaviour.
    /// @dev This function checks if the consensus state at the new height is different than the one in the mapping.
    /// @dev This function does not check timestamp misbehaviour (a niche case).
    /// @param output The public values of the update client program.
    function checkUpdateResult(UpdateClientOutput memory output) private view returns (UpdateResult) {
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

    function verifySP1Proof(SP1Proof memory proof) private view {
        VERIFIER.verifyProof(proof.vKey, proof.publicValues, proof.proof);
    }

    /// @notice A dummy function to generate the ABI for the parameters.
    function abiPublicTypes(
        MembershipOutput memory o1,
        UcAndMembershipOutput memory o2,
        MsgUpdateClient memory o3,
        MembershipProof memory o4,
        SP1MembershipProof memory o5,
        SP1MembershipAndUpdateClientProof memory o6
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
