// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {ICS07Tendermint} from "ibc-lite-shared/ics07-tendermint/ICS07Tendermint.sol";

struct SP1ICS07TendermintGenesisJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 vkey;
}

contract SP1TendermintScript is Script {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;

    function setUp() public {}

    // Deploy the SP1 Tendermint contract with the supplied initialization parameters.
    function run() public returns (address) {
        vm.startBroadcast();

        // Read the initialization parameters for the SP1 Tendermint contract.
        SP1ICS07TendermintGenesisJson memory genesis = loadGenesis(
            "genesis.json"
        );

        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            genesis.vkey,
            address(verifier),
            genesis.trustedClientState,
            genesis.trustedConsensusState
        );

        (
            string memory chain_id,
            ICS07Tendermint.TrustThreshold memory trust_level,
            ICS07Tendermint.Height memory latest_height,
            uint64 trusting_period,
            uint64 unbonding_period,
            bool is_frozen
        ) = ics07Tendermint.clientState();

        assert(keccak256(bytes(chain_id)) == keccak256(bytes("mocha-4")));
        assert(trust_level.numerator == 1);
        assert(trust_level.denominator == 3);
        assert(latest_height.revision_number == 4);
        // assert(latest_height.revision_height == 2110658);
        assert(trusting_period == 1_209_600_000_000_000);
        assert(unbonding_period == 1_209_600_000_000_000);
        assert(is_frozen == false);

        vm.stopBroadcast();

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
        bytes32 vkey = json.readBytes32(".vkey");

        SP1ICS07TendermintGenesisJson
            memory fixture = SP1ICS07TendermintGenesisJson({
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                vkey: vkey
            });

        return fixture;
    }
}
