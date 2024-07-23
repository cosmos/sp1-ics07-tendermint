// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { stdError } from "forge-std/StdError.sol";
import { ICS07Tendermint } from "../src/ics07-tendermint/ICS07Tendermint.sol";
import { SP1ICS07Tendermint } from "../src/SP1ICS07Tendermint.sol";
import { SP1Verifier } from "@sp1-contracts/v1.0.0-rc1/SP1Verifier.sol";
import { SP1MockVerifier } from "@sp1-contracts/SP1MockVerifier.sol";

struct SP1ICS07GenesisFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
    bytes32 ucAndMembershipVkey;
}

abstract contract SP1ICS07TendermintTest is Test {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;
    SP1ICS07Tendermint public mockIcs07Tendermint;

    SP1ICS07GenesisFixtureJson internal genesisFixture;
    SP1ICS07GenesisFixtureJson internal mockGenesisFixture;

    function setUpTest(string memory fileName, string memory mockFileName) public {
        genesisFixture = loadGenesisFixture(fileName);

        ICS07Tendermint.ConsensusState memory trustedConsensusState =
            abi.decode(genesisFixture.trustedConsensusState, (ICS07Tendermint.ConsensusState));

        bytes32 trustedConsensusHash = keccak256(abi.encode(trustedConsensusState));

        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            genesisFixture.updateClientVkey,
            genesisFixture.membershipVkey,
            genesisFixture.ucAndMembershipVkey,
            address(verifier),
            genesisFixture.trustedClientState,
            trustedConsensusHash
        );

        mockGenesisFixture = loadGenesisFixture(mockFileName);

        ICS07Tendermint.ConsensusState memory mockTrustedConsensusState =
            abi.decode(mockGenesisFixture.trustedConsensusState, (ICS07Tendermint.ConsensusState));

        bytes32 mockTrustedConsensusHash = keccak256(abi.encode(mockTrustedConsensusState));

        SP1MockVerifier mockVerifier = new SP1MockVerifier();
        mockIcs07Tendermint = new SP1ICS07Tendermint(
            mockGenesisFixture.updateClientVkey,
            mockGenesisFixture.membershipVkey,
            mockGenesisFixture.ucAndMembershipVkey,
            address(mockVerifier),
            mockGenesisFixture.trustedClientState,
            mockTrustedConsensusHash
        );

        ICS07Tendermint.ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(keccak256(abi.encode(clientState)) == keccak256(mockGenesisFixture.trustedClientState));

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusStateHash(clientState.latest_height.revision_height);
        assert(consensusHash == mockTrustedConsensusHash);
    }

    function loadGenesisFixture(string memory fileName) public view returns (SP1ICS07GenesisFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(".trustedConsensusState");
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");
        bytes32 ucAndMembershipVkey = json.readBytes32(".ucAndMembershipVkey");

        SP1ICS07GenesisFixtureJson memory fix = SP1ICS07GenesisFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            updateClientVkey: updateClientVkey,
            membershipVkey: membershipVkey,
            ucAndMembershipVkey: ucAndMembershipVkey
        });

        return fix;
    }
}
