// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";

struct SP1ICS07TendermintGenesisJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
    bytes32 ucAndMembershipVkey;
}

contract SP1TendermintScript is Script {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;

    function setUp() public {}

    // Deploy the SP1 Tendermint contract with the supplied initialization parameters.
    function run() public returns (address) {
        // Read the initialization parameters for the SP1 Tendermint contract.
        SP1ICS07TendermintGenesisJson memory genesis = loadGenesis(
            "genesis.json"
        );

        ICS07Tendermint.ConsensusState memory trustedConsensusState = abi
            .decode(
                genesis.trustedConsensusState,
                (ICS07Tendermint.ConsensusState)
            );

        bytes32 trustedConsensusHash = keccak256(
            abi.encode(trustedConsensusState)
        );

        vm.startBroadcast();

        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            genesis.updateClientVkey,
            genesis.membershipVkey,
            genesis.ucAndMembershipVkey,
            address(verifier),
            genesis.trustedClientState,
            trustedConsensusHash
        );

        vm.stopBroadcast();

        ICS07Tendermint.ClientState memory clientState = ics07Tendermint
            .getClientState();
        assert(
            keccak256(abi.encode(clientState)) ==
                keccak256(genesis.trustedClientState)
        );

        bytes32 consensusHash = ics07Tendermint.getConsensusStateHash(
            clientState.latest_height.revision_height
        );
        assert(consensusHash == keccak256(abi.encode(trustedConsensusState)));

        return address(ics07Tendermint);
    }

    function loadGenesis(
        string memory fileName
    ) public view returns (SP1ICS07TendermintGenesisJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(
            ".trustedConsensusState"
        );
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");
        bytes32 ucAndMembershipVkey = json.readBytes32(".ucAndMembershipVkey");

        SP1ICS07TendermintGenesisJson
            memory fixture = SP1ICS07TendermintGenesisJson({
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                updateClientVkey: updateClientVkey,
                membershipVkey: membershipVkey,
                ucAndMembershipVkey: ucAndMembershipVkey
            });

        return fixture;
    }
}
