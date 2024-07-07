// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdError} from "forge-std/StdError.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {SP1MockVerifier} from "@sp1-contracts/SP1MockVerifier.sol";

struct SP1ICS07GenesisFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
}

abstract contract SP1ICS07TendermintTest is Test {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;
    SP1ICS07Tendermint public mockIcs07Tendermint;

    SP1ICS07GenesisFixtureJson internal genesisFixture;
    SP1ICS07GenesisFixtureJson internal mockGenesisFixture;

    function setUpTest(
        string memory fileName,
        string memory mockFileName
    ) public {
        genesisFixture = loadGenesisFixture(fileName);

        ICS07Tendermint.ConsensusState memory trustedConsensusState = abi
            .decode(
                genesisFixture.trustedConsensusState,
                (ICS07Tendermint.ConsensusState)
            );

        bytes32 trustedConsensusHash = keccak256(
            abi.encode(trustedConsensusState)
        );

        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            genesisFixture.updateClientVkey,
            genesisFixture.membershipVkey,
            address(verifier),
            genesisFixture.trustedClientState,
            trustedConsensusHash
        );

        mockGenesisFixture = loadGenesisFixture(mockFileName);

        ICS07Tendermint.ConsensusState memory mockTrustedConsensusState = abi
            .decode(
                mockGenesisFixture.trustedConsensusState,
                (ICS07Tendermint.ConsensusState)
            );

        bytes32 mockTrustedConsensusHash = keccak256(
            abi.encode(mockTrustedConsensusState)
        );

        SP1MockVerifier mockVerifier = new SP1MockVerifier();
        mockIcs07Tendermint = new SP1ICS07Tendermint(
            mockGenesisFixture.updateClientVkey,
            mockGenesisFixture.membershipVkey,
            address(mockVerifier),
            mockGenesisFixture.trustedClientState,
            mockTrustedConsensusHash
        );

        ICS07Tendermint.ClientState memory clientState = mockIcs07Tendermint
            .getClientState();
        assert(
            keccak256(bytes(clientState.chain_id)) ==
                keccak256(bytes("mocha-4"))
        );
        assert(clientState.trust_level.numerator == 1);
        assert(clientState.trust_level.denominator == 3);
        assert(clientState.latest_height.revision_number == 4);
        assert(clientState.latest_height.revision_height == 2110658);
        assert(clientState.trusting_period == 1_209_600);
        assert(clientState.unbonding_period == 1_209_600);
        assert(clientState.is_frozen == false);

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusState(2110658);
        assert(consensusHash == mockTrustedConsensusHash);
    }

    function loadGenesisFixture(
        string memory fileName
    ) public view returns (SP1ICS07GenesisFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(
            ".trustedConsensusState"
        );
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");

        SP1ICS07GenesisFixtureJson memory fix = SP1ICS07GenesisFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            updateClientVkey: updateClientVkey,
            membershipVkey: membershipVkey
        });

        return fix;
    }
}
