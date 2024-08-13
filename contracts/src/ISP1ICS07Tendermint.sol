// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { ILightClient } from "solidity-ibc/interfaces/ILightClient.sol";
import { IICS07TendermintMsgs } from "../src/msgs/IICS07TendermintMsgs.sol";

/// @title ISP1ICS07Tendermint
/// @notice ISP1ICS07Tendermint is the interface for the ICS07 Tendermint light client
interface ISP1ICS07Tendermint is ILightClient {
    /// @notice Returns the client state.
    /// @return The client state.
    function getClientState() external view returns (IICS07TendermintMsgs.ClientState memory);

    /// @notice Returns the consensus state keccak256 hash at the given revision height.
    /// @param revisionHeight The revision height.
    /// @return The consensus state at the given revision height.
    function getConsensusStateHash(uint32 revisionHeight) external view returns (bytes32);
}
