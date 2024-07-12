// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ics07-tendermint/ICS07Tendermint.sol";
import {UpdateClientProgram} from "./ics07-tendermint/UpdateClientProgram.sol";

/// @title SP1 ICS07 Tendermint Light Client Interface
/// @author srdtrk
/// @notice This interface is used to interact with the SP1 ICS07 Tendermint Light Client
interface ISP1ICS07Tendermint {
    /// @notice Get the client state
    function getClientState()
        external
        view
        returns (ICS07Tendermint.ClientState memory);

    /// @notice Get the consensus state keccak256 hash at the given height
    function getConsensusStateHash(uint32) external view returns (bytes32);

    /// @notice Returns the verifier information.
    /// @return Returns the verifier contract address and the program verification keys.
    function getVerifierInfo()
        external
        view
        returns (address, bytes32, bytes32, bytes32);

    /// @notice The entrypoint for updating the client.
    /// @dev This function verifies the public values and forwards the proof to the SP1 verifier.
    /// @param proof The encoded proof.
    /// @param publicValues The encoded public values.
    /// @return The result of the update.
    function updateClient(
        bytes calldata proof,
        bytes calldata publicValues
    ) external returns (UpdateClientProgram.UpdateResult);

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
    ) external view;

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
    ) external returns (UpdateClientProgram.UpdateResult);
}
