// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdError} from "forge-std/StdError.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1ICS07TendermintTest} from "./SP1ICS07TendermintTest.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {SP1MockVerifier} from "@sp1-contracts/SP1MockVerifier.sol";
import {MembershipProgram} from "../src/ics07-tendermint/MembershipProgram.sol";

struct SP1ICS07MembershipFixtureJson {
    uint32 proofHeight;
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
    bytes32 commitmentRoot;
    bytes publicValues;
    bytes proof;
    bytes kvPairsBz;
}

abstract contract MembershipTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07MembershipFixtureJson public fixture;
    SP1ICS07MembershipFixtureJson public mockFixture;

    function setUpTestWithFixtures(
        string memory fileName,
        string memory mockFileName
    ) public {
        fixture = loadFixture(fileName);
        mockFixture = loadFixture(mockFileName);

        setUpTest(fileName, mockFileName);
    }

    function kvPairs() public view returns (MembershipProgram.KVPair[] memory) {
        return abi.decode(fixture.kvPairsBz, (MembershipProgram.KVPair[]));
    }

    function mockKvPairs()
        public
        view
        returns (MembershipProgram.KVPair[] memory)
    {
        return abi.decode(mockFixture.kvPairsBz, (MembershipProgram.KVPair[]));
    }

    function loadFixture(
        string memory fileName
    ) public view returns (SP1ICS07MembershipFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(
            ".trustedConsensusState"
        );
        uint32 proofHeight = uint32(json.readUint(".proofHeight"));
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");
        bytes32 commitmentRoot = json.readBytes32(".commitmentRoot");
        bytes memory publicValues = json.readBytes(".publicValues");
        bytes memory proof = json.readBytes(".proof");
        bytes memory kvPairsBz = json.readBytes(".kvPairs");

        SP1ICS07MembershipFixtureJson
            memory fix = SP1ICS07MembershipFixtureJson({
                commitmentRoot: commitmentRoot,
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                proofHeight: proofHeight,
                updateClientVkey: updateClientVkey,
                membershipVkey: membershipVkey,
                publicValues: publicValues,
                proof: proof,
                kvPairsBz: kvPairsBz
            });

        return fix;
    }
}
