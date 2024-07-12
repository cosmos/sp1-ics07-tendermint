// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICS07Tendermint} from "./ics07-tendermint/ICS07Tendermint.sol";

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
}
