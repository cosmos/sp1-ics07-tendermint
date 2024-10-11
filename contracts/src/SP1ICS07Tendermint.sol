// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { IICS07TendermintMsgs } from "./msgs/IICS07TendermintMsgs.sol";
import { IUpdateClientMsgs } from "./msgs/IUpdateClientMsgs.sol";
import { IMembershipMsgs } from "./msgs/IMembershipMsgs.sol";
import { IUpdateClientAndMembershipMsgs } from "./msgs/IUcAndMembershipMsgs.sol";
import { IMisbehaviourMsgs } from "./msgs/IMisbehaviourMsgs.sol";
import { ISP1Verifier } from "@sp1-contracts/ISP1Verifier.sol";
import { ISP1ICS07TendermintErrors } from "./errors/ISP1ICS07TendermintErrors.sol";
import { ISP1ICS07Tendermint } from "./ISP1ICS07Tendermint.sol";
import { ILightClientMsgs } from "solidity-ibc/msgs/ILightClientMsgs.sol";
import { ILightClient } from "solidity-ibc/interfaces/ILightClient.sol";
import { Paths } from "./utils/Paths.sol";
import { UnionMembership } from "./utils/UnionMembership.sol";

/// @title SP1 ICS07 Tendermint Light Client
/// @author srdtrk
/// @notice This contract implements an ICS07 IBC tendermint light client using SP1.
/// @custom:poc This is a proof of concept implementation.
contract SP1ICS07Tendermint is
    IICS07TendermintMsgs,
    IUpdateClientMsgs,
    IMembershipMsgs,
    IUpdateClientAndMembershipMsgs,
    IMisbehaviourMsgs,
    ISP1ICS07TendermintErrors,
    ILightClientMsgs,
    ISP1ICS07Tendermint
{
    /// @inheritdoc ISP1ICS07Tendermint
    bytes32 public immutable UPDATE_CLIENT_PROGRAM_VKEY;
    /// @inheritdoc ISP1ICS07Tendermint
    bytes32 public immutable MEMBERSHIP_PROGRAM_VKEY;
    /// @inheritdoc ISP1ICS07Tendermint
    bytes32 public immutable UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY;
    /// @inheritdoc ISP1ICS07Tendermint
    bytes32 public immutable MISBEHAVIOUR_PROGRAM_VKEY;
    /// @inheritdoc ISP1ICS07Tendermint
    ISP1Verifier public immutable VERIFIER;

    /// @notice The ICS07Tendermint client state
    ClientState private clientState;
    /// @notice The mapping from height to consensus state keccak256 hashes.
    mapping(uint32 height => bytes32 hash) private consensusStateHashes;
    /// @notice The collection of verified SP1 proofs for caching.
    mapping(bytes32 sp1ProofHash => bool isVerified) private verifiedProofs;

    /// @notice Allowed clock drift in seconds.
    /// @inheritdoc ISP1ICS07Tendermint
    uint16 public constant ALLOWED_SP1_CLOCK_DRIFT = 3000; // 3000 seconds

    /// @notice The constructor sets the program verification key and the initial client and consensus states.
    /// @param updateClientProgramVkey The verification key for the update client program.
    /// @param membershipProgramVkey The verification key for the verify (non)membership program.
    /// @param updateClientAndMembershipProgramVkey The verification key for the update client and membership program.
    /// @param misbehaviourProgramVkey The verification key for the misbehaviour program.
    /// @param verifier The address of the SP1 verifier contract.
    /// @param _clientState The encoded initial client state.
    /// @param _consensusState The encoded initial consensus state.
    constructor(
        bytes32 updateClientProgramVkey,
        bytes32 membershipProgramVkey,
        bytes32 updateClientAndMembershipProgramVkey,
        bytes32 misbehaviourProgramVkey,
        address verifier,
        bytes memory _clientState,
        bytes32 _consensusState
    ) {
        UPDATE_CLIENT_PROGRAM_VKEY = updateClientProgramVkey;
        MEMBERSHIP_PROGRAM_VKEY = membershipProgramVkey;
        UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY = updateClientAndMembershipProgramVkey;
        MISBEHAVIOUR_PROGRAM_VKEY = misbehaviourProgramVkey;
        VERIFIER = ISP1Verifier(verifier);

        clientState = abi.decode(_clientState, (ClientState));
        consensusStateHashes[clientState.latestHeight.revisionHeight] = _consensusState;
    }

    /// @inheritdoc ISP1ICS07Tendermint
    function getClientState() public view returns (ClientState memory) {
        return clientState;
    }

    /// @inheritdoc ISP1ICS07Tendermint
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
    /// @inheritdoc ILightClient
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
    /// @inheritdoc ILightClient
    function membership(MsgMembership calldata msgMembership) public returns (uint256 timestamp) {
        bytes calldata proof = msgMembership.proof;
        MembershipProof calldata membershipProof;
        assembly {
            membershipProof := proof.offset
        }
        if (membershipProof.proofType == MembershipProofType.SP1MembershipProof) {
            return handleSP1MembershipProof(
                msgMembership.proofHeight, membershipProof.proof, msgMembership.path, msgMembership.value
            );
        } else if (membershipProof.proofType == MembershipProofType.SP1MembershipAndUpdateClientProof) {
            return handleSP1UpdateClientAndMembership(
                msgMembership.proofHeight, membershipProof.proof, msgMembership.path, msgMembership.value
            );
        } else if (membershipProof.proofType == MembershipProofType.UnionMembershipProof) {
            return handleUnionMembershipProof(
                msgMembership.proofHeight, membershipProof.proof, msgMembership.path, msgMembership.value
            );
        } else {
            revert UnknownMembershipProofType(uint8(membershipProof.proofType));
        }
    }

    /// @notice The entrypoint for misbehaviour.
    /// @inheritdoc ILightClient
    function misbehaviour(bytes calldata misbehaviourMsg) public {
        MsgSubmitMisbehaviour memory msgSubmitMisbehaviour = abi.decode(misbehaviourMsg, (MsgSubmitMisbehaviour));
        if (msgSubmitMisbehaviour.sp1Proof.vKey != MISBEHAVIOUR_PROGRAM_VKEY) {
            revert VerificationKeyMismatch(MISBEHAVIOUR_PROGRAM_VKEY, msgSubmitMisbehaviour.sp1Proof.vKey);
        }

        MisbehaviourOutput memory output = abi.decode(msgSubmitMisbehaviour.sp1Proof.publicValues, (MisbehaviourOutput));

        validateMisbehaviourOutput(output);

        verifySP1Proof(msgSubmitMisbehaviour.sp1Proof);

        // If the misbehaviour and proof is valid, the client needs to be frozen
        clientState.isFrozen = true;
    }

    /// @notice The entrypoint for upgrading the client.
    /// @inheritdoc ILightClient
    function upgradeClient(bytes calldata) public pure {
        // TODO: Not yet implemented. (#78)
        revert FeatureNotSupported();
    }

    function handleUnionMembershipProof(
        Height calldata proofHeight,
        bytes calldata proofBytes,
        bytes[] calldata kvPath,
        bytes calldata kvValue
    )
        private
        view
        returns (uint256)
    {
        if (kvPath.length != 2) {
            revert LengthIsOutOfRange(kvPath.length, 2, 2);
        }

        UnionMembershipProof calldata uProof;
        assembly {
            uProof := proofBytes.offset
        }

        validateMembershipOutput(
            uProof.trustedConsensusState.root, proofHeight.revisionHeight, uProof.trustedConsensusState
        );

        if (
            !UnionMembership.verify(uProof.trustedConsensusState.root, uProof.ics23Proof, kvPath[0], kvPath[1], kvValue)
        ) {
            revert InvalidMembershipProof();
        }

        return uProof.trustedConsensusState.timestamp;
    }

    /// @notice Handles the `SP1MembershipProof` proof type.
    /// @param proofHeight The height of the proof.
    /// @param proofBytes The encoded proof.
    /// @param kvPath The path of the key-value pair.
    /// @param kvValue The value of the key-value pair.
    /// @return The timestamp of the trusted consensus state.
    function handleSP1MembershipProof(
        Height calldata proofHeight,
        bytes calldata proofBytes,
        bytes[] calldata kvPath,
        bytes calldata kvValue
    )
        private
        returns (uint256)
    {
        if (proofHeight.revisionNumber != clientState.latestHeight.revisionNumber) {
            revert ProofHeightMismatch(
                proofHeight.revisionNumber,
                proofHeight.revisionHeight,
                clientState.latestHeight.revisionNumber,
                clientState.latestHeight.revisionHeight
            );
        }

        SP1MembershipProof memory proof = abi.decode(proofBytes, (SP1MembershipProof));
        if (proof.sp1Proof.vKey != MEMBERSHIP_PROGRAM_VKEY) {
            revert VerificationKeyMismatch(MEMBERSHIP_PROGRAM_VKEY, proof.sp1Proof.vKey);
        }

        MembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (MembershipOutput));
        if (output.kvPairs.length == 0 || output.kvPairs.length > 256) {
            revert LengthIsOutOfRange(output.kvPairs.length, 1, 256);
        }

        {
            // loop through the key-value pairs and validate them
            bool found = false;
            for (uint8 i = 0; i < output.kvPairs.length; i++) {
                if (!Paths.equal(output.kvPairs[i].path, kvPath)) {
                    continue;
                }

                if (keccak256(output.kvPairs[i].value) != keccak256(kvValue)) {
                    revert MembershipProofValueMismatch(kvValue, output.kvPairs[i].value);
                }

                found = true;
                break;
            }
            if (!found) {
                revert MembershipProofKeyNotFound(kvPath);
            }
        }

        validateMembershipOutput(output.commitmentRoot, proofHeight.revisionHeight, proof.trustedConsensusState);

        // We avoid the cost of caching for single kv pairs, as reusing the proof is not necessary
        if (output.kvPairs.length == 1) {
            verifySP1Proof(proof.sp1Proof);
        } else {
            verifySP1ProofCached(proof.sp1Proof);
        }

        return proof.trustedConsensusState.timestamp;
    }

    /// @notice The entrypoint for handling the `SP1MembershipAndUpdateClientProof` proof type.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proofHeight The height of the proof.
    /// @param proofBytes The encoded proof.
    /// @param kvPath The path of the key-value pair.
    /// @param kvValue The value of the key-value pair.
    /// @return The timestamp of the new consensus state.
    // solhint-disable-next-line code-complexity
    function handleSP1UpdateClientAndMembership(
        Height calldata proofHeight,
        bytes calldata proofBytes,
        bytes[] calldata kvPath,
        bytes calldata kvValue
    )
        private
        returns (uint256)
    {
        // validate proof and deserialize output
        UcAndMembershipOutput memory output;
        {
            SP1MembershipAndUpdateClientProof memory proof = abi.decode(proofBytes, (SP1MembershipAndUpdateClientProof));
            if (proof.sp1Proof.vKey != UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY) {
                revert VerificationKeyMismatch(UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY, proof.sp1Proof.vKey);
            }

            output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
            if (output.kvPairs.length == 0 || output.kvPairs.length > 256) {
                revert LengthIsOutOfRange(output.kvPairs.length, 1, 256);
            }

            if (
                proofHeight.revisionHeight != output.updateClientOutput.newHeight.revisionHeight
                    || proofHeight.revisionNumber != output.updateClientOutput.newHeight.revisionNumber
            ) {
                revert ProofHeightMismatch(
                    proofHeight.revisionNumber,
                    proofHeight.revisionHeight,
                    output.updateClientOutput.newHeight.revisionNumber,
                    output.updateClientOutput.newHeight.revisionHeight
                );
            }

            validateUpdateClientPublicValues(output.updateClientOutput);

            // We avoid the cost of caching for single kv pairs, as reusing the proof is not necessary
            if (output.kvPairs.length == 1) {
                verifySP1Proof(proof.sp1Proof);
            } else {
                verifySP1ProofCached(proof.sp1Proof);
            }
        }

        // check update result
        {
            UpdateResult updateResult = checkUpdateResult(output.updateClientOutput);
            if (updateResult == UpdateResult.Update) {
                // adding the new consensus state to the mapping
                if (proofHeight.revisionHeight > clientState.latestHeight.revisionHeight) {
                    clientState.latestHeight = proofHeight;
                }
                consensusStateHashes[proofHeight.revisionHeight] =
                    keccak256(abi.encode(output.updateClientOutput.newConsensusState));
            } else if (updateResult == UpdateResult.Misbehaviour) {
                clientState.isFrozen = true;
                revert CannotHandleMisbehavior();
            } // else: NoOp
        }

        // loop through the key-value pairs and validate them
        {
            bool found = false;
            for (uint8 i = 0; i < output.kvPairs.length; i++) {
                if (!Paths.equal(output.kvPairs[i].path, kvPath)) {
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
        validateEnv(output.env);

        bytes32 outputConsensusStateHash = keccak256(abi.encode(output.trustedConsensusState));
        bytes32 trustedConsensusStateHash = getConsensusStateHash(output.trustedHeight.revisionHeight);
        if (outputConsensusStateHash != trustedConsensusStateHash) {
            revert ConsensusStateHashMismatch(trustedConsensusStateHash, outputConsensusStateHash);
        }
    }

    /// @notice Validates the SP1ICS07MisbehaviourOutput public values.
    /// @param output The public values.
    function validateMisbehaviourOutput(MisbehaviourOutput memory output) private view {
        if (clientState.isFrozen) {
            revert FrozenClientState();
        }
        validateEnv(output.env);

        // make sure the trusted consensus state from header 1 is known (trusted) by matching it with the the one in the
        // mapping
        bytes32 outputConsensusStateHash1 = keccak256(abi.encode(output.trustedConsensusState1));
        bytes32 trustedConsensusState1 = getConsensusStateHash(output.trustedHeight1.revisionHeight);
        if (outputConsensusStateHash1 != trustedConsensusState1) {
            revert ConsensusStateHashMismatch(trustedConsensusState1, outputConsensusStateHash1);
        }

        // make sure the trusted consensus state from header 2 is known (trusted) by matching it with the the one in the
        // mapping
        bytes32 outputConsensusStateHash2 = keccak256(abi.encode(output.trustedConsensusState2));
        bytes32 trustedConsensusState2 = getConsensusStateHash(output.trustedHeight2.revisionHeight);
        if (outputConsensusStateHash2 != trustedConsensusState2) {
            revert ConsensusStateHashMismatch(trustedConsensusState2, outputConsensusStateHash2);
        }
    }

    /// @notice Validates the Env public values.
    /// @param env The public values.
    function validateEnv(Env memory env) private view {
        if (env.now > block.timestamp) {
            revert ProofIsInTheFuture(block.timestamp, env.now);
        }
        if (block.timestamp - env.now > ALLOWED_SP1_CLOCK_DRIFT) {
            revert ProofIsTooOld(block.timestamp, env.now);
        }
        if (keccak256(bytes(env.chainId)) != keccak256(bytes(clientState.chainId))) {
            revert ChainIdMismatch(clientState.chainId, env.chainId);
        }
        if (
            env.trustThreshold.numerator != clientState.trustLevel.numerator
                || env.trustThreshold.denominator != clientState.trustLevel.denominator
        ) {
            revert TrustThresholdMismatch(
                clientState.trustLevel.numerator,
                clientState.trustLevel.denominator,
                env.trustThreshold.numerator,
                env.trustThreshold.denominator
            );
        }
        if (env.trustingPeriod != clientState.trustingPeriod) {
            revert TrustingPeriodMismatch(clientState.trustingPeriod, env.trustingPeriod);
        }
        if (env.trustingPeriod > clientState.unbondingPeriod) {
            revert TrustingPeriodTooLong(env.trustingPeriod, clientState.unbondingPeriod);
        }
    }

    /// @notice Checks for basic misbehaviour.
    /// @dev This function checks if the consensus state at the new height is different than the one in the mapping
    /// @dev or if the timestamp is not increasing.
    /// @dev If any of these conditions are met, it returns a Misbehaviour UpdateResult.
    /// @param output The public values of the update client program.
    /// @return The result of the update.
    function checkUpdateResult(UpdateClientOutput memory output) private view returns (UpdateResult) {
        bytes32 consensusStateHash = consensusStateHashes[output.newHeight.revisionHeight];
        if (consensusStateHash == bytes32(0)) {
            // No consensus state at the new height, so no misbehaviour
            return UpdateResult.Update;
        } else if (
            consensusStateHash != keccak256(abi.encode(output.newConsensusState))
                || output.trustedConsensusState.timestamp >= output.newConsensusState.timestamp
        ) {
            // The consensus state at the new height is different than the one in the mapping
            // or the timestamp is not increasing
            return UpdateResult.Misbehaviour;
        } else {
            // The consensus state at the new height is the same as the one in the mapping
            return UpdateResult.NoOp;
        }
    }

    /// @notice Verifies the SP1 proof
    /// @param proof The SP1 proof.
    function verifySP1Proof(SP1Proof memory proof) private view {
        VERIFIER.verifyProof(proof.vKey, proof.publicValues, proof.proof);
    }

    /// @notice Verifies the SP1 proof and stores the hash of the proof.
    /// @dev If the proof is already cached, it does not verify the proof again.
    /// @param proof The SP1 proof.
    function verifySP1ProofCached(SP1Proof memory proof) private {
        bytes32 proofHash = keccak256(abi.encode(proof));
        if (verifiedProofs[proofHash]) {
            return;
        }

        VERIFIER.verifyProof(proof.vKey, proof.publicValues, proof.proof);
        verifiedProofs[proofHash] = true;
    }

    /// @notice A dummy function to generate the ABI for the parameters.
    /// @param o1 The MembershipOutput.
    /// @param o2 The UcAndMembershipOutput.
    /// @param o3 The MsgUpdateClient.
    /// @param o4 The MembershipProof.
    /// @param o5 The SP1MembershipProof.
    /// @param o6 The SP1MembershipAndUpdateClientProof.
    /// @param o7 The MisbehaviourOutput.
    /// @param o8 The MsgSubmitMisbehaviour.
    function abiPublicTypes(
        MembershipOutput memory o1,
        UcAndMembershipOutput memory o2,
        MsgUpdateClient memory o3,
        MembershipProof memory o4,
        SP1MembershipProof memory o5,
        SP1MembershipAndUpdateClientProof memory o6,
        MisbehaviourOutput memory o7,
        MsgSubmitMisbehaviour memory o8
    )
        public
        pure
    // solhint-disable-next-line no-empty-blocks
    {
        // This is a dummy function to generate the ABI for outputs
        // so that it can be used in the SP1 verifier contract.
        // The function is not used in the contract.
    }
}
