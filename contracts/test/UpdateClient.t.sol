// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdError} from "forge-std/StdError.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";
import {UpdateClientProgram} from "../src/ics07-tendermint/UpdateClientProgram.sol";
import {SP1ICS07TendermintTest} from "./SP1ICS07TendermintTest.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {SP1MockVerifier} from "@sp1-contracts/SP1MockVerifier.sol";

struct SP1ICS07UpdateClientFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes targetConsensusState;
    uint32 targetHeight;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
    bytes publicValues;
    bytes proof;
}

contract SP1ICS07UpdateClientTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07UpdateClientFixtureJson public fixture;
    SP1ICS07UpdateClientFixtureJson public mockFixture;

    function setUp() public {
        fixture = loadFixture("update_client_fixture.json");
        mockFixture = loadFixture("mock_update_client_fixture.json");

        setUpTest(
            "update_client_fixture.json",
            "mock_update_client_fixture.json"
        );

        ICS07Tendermint.ClientState memory clientState = mockIcs07Tendermint
            .getClientState();
        assert(
            clientState.latest_height.revision_height < mockFixture.targetHeight
        );
    }

    function loadFixture(
        string memory fileName
    ) public view returns (SP1ICS07UpdateClientFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(
            ".trustedConsensusState"
        );
        bytes memory targetConsensusState = json.readBytes(
            ".targetConsensusState"
        );
        uint32 targetHeight = uint32(json.readUint(".targetHeight"));
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");
        bytes memory publicValues = json.readBytes(".publicValues");
        bytes memory proof = json.readBytes(".proof");

        SP1ICS07UpdateClientFixtureJson
            memory fix = SP1ICS07UpdateClientFixtureJson({
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                targetConsensusState: targetConsensusState,
                targetHeight: targetHeight,
                updateClientVkey: updateClientVkey,
                membershipVkey: membershipVkey,
                publicValues: publicValues,
                proof: proof
            });

        return fix;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClient() public {
        // set a correct timestamp
        UpdateClientProgram.UpdateClientOutput memory output = abi.decode(
            fixture.publicValues,
            (UpdateClientProgram.UpdateClientOutput)
        );
        vm.warp(output.env.now + 300);

        // run verify
        ics07Tendermint.verifyIcs07UpdateClientProof(
            fixture.proof,
            fixture.publicValues
        );

        // to console
        console.log("UpdateClient gas used: ", vm.lastCallGas().gasTotalUsed);

        ICS07Tendermint.ClientState memory clientState = ics07Tendermint
            .getClientState();
        assert(
            keccak256(bytes(clientState.chain_id)) ==
                keccak256(bytes("mocha-4"))
        );
        assert(clientState.trust_level.numerator == 1);
        assert(clientState.trust_level.denominator == 3);
        assert(clientState.latest_height.revision_number == 4);
        assert(
            clientState.latest_height.revision_height == fixture.targetHeight
        );
        assert(clientState.trusting_period == 1_209_600);
        assert(clientState.unbonding_period == 1_209_600);
        assert(clientState.is_frozen == false);

        bytes32 consensusHash = ics07Tendermint.getConsensusState(
            fixture.targetHeight
        );
        ICS07Tendermint.ConsensusState memory expConsensusState = abi.decode(
            fixture.targetConsensusState,
            (ICS07Tendermint.ConsensusState)
        );
        assert(consensusHash == keccak256(abi.encode(expConsensusState)));
    }

    // Confirm that submitting an empty proof passes the mock verifier.
    function test_ValidMockUpdateClient() public {
        // set a correct timestamp
        UpdateClientProgram.UpdateClientOutput memory output = abi.decode(
            mockFixture.publicValues,
            (UpdateClientProgram.UpdateClientOutput)
        );
        vm.warp(output.env.now + 300);

        // run verify
        mockIcs07Tendermint.verifyIcs07UpdateClientProof(
            bytes(""),
            mockFixture.publicValues
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
        assert(
            clientState.latest_height.revision_height ==
                mockFixture.targetHeight
        );
        assert(clientState.trusting_period == 1_209_600);
        assert(clientState.unbonding_period == 1_209_600);
        assert(clientState.is_frozen == false);

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusState(
            mockFixture.targetHeight
        );
        ICS07Tendermint.ConsensusState memory expConsensusState = abi.decode(
            fixture.targetConsensusState,
            (ICS07Tendermint.ConsensusState)
        );
        assert(consensusHash == keccak256(abi.encode(expConsensusState)));
    }

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockUpdateClient() public {
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07UpdateClientProof(
            bytes("invalid"),
            mockFixture.publicValues
        );
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_UpdateClient() public {
        vm.expectRevert();
        ics07Tendermint.verifyIcs07UpdateClientProof(
            bytes("invalid"),
            fixture.publicValues
        );
    }
}
