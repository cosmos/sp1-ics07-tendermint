// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdError} from "forge-std/StdError.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1ICS07TendermintTest} from "./SP1ICS07TendermintTest.sol";
import {MembershipProgram} from "../src/ics07-tendermint/MembershipProgram.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {SP1MockVerifier} from "@sp1-contracts/SP1MockVerifier.sol";

struct SP1ICS07VerifyMembershipFixtureJson {
    uint32 proofHeight;
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 verifyMembershipVkey;
    bytes32 commitmentRoot;
    bytes publicValues;
    bytes proof;
    bytes value;
}

// set constant string
string constant verifyMembershipPath = "clients/07-tendermint-0/clientState";

contract SP1ICS07VerifyMembershipTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07VerifyMembershipFixtureJson public fixture;
    SP1ICS07VerifyMembershipFixtureJson public mockFixture;

    function setUp() public {
        fixture = loadFixture("verify_membership_fixture.json");
        mockFixture = loadFixture("mock_verify_membership_fixture.json");

        setUpTest(
            "verify_membership_fixture.json",
            "mock_verify_membership_fixture.json"
        );
    }

    function loadFixture(
        string memory fileName
    ) public view returns (SP1ICS07VerifyMembershipFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(
            ".trustedConsensusState"
        );
        uint32 proofHeight = uint32(json.readUint(".proofHeight"));
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 verifyMembershipVkey = json.readBytes32(
            ".verifyMembershipVkey"
        );
        bytes32 commitmentRoot = json.readBytes32(".commitmentRoot");
        bytes memory publicValues = json.readBytes(".publicValues");
        bytes memory proof = json.readBytes(".proof");
        bytes memory value = json.readBytes(".value");

        SP1ICS07VerifyMembershipFixtureJson
            memory fix = SP1ICS07VerifyMembershipFixtureJson({
                commitmentRoot: commitmentRoot,
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                proofHeight: proofHeight,
                updateClientVkey: updateClientVkey,
                verifyMembershipVkey: verifyMembershipVkey,
                publicValues: publicValues,
                proof: proof,
                value: value
            });

        return fix;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidSP1ICS07VerifyMembership() public view {
        ics07Tendermint.verifyIcs07MembershipProof(
            fixture.proof,
            fixture.publicValues,
            fixture.proofHeight,
            fixture.trustedConsensusState,
            new bytes32[](0) // TODO: add kvPairHashes
        );

        // to console
        console.log(
            "VerifyMembership gas used: ",
            vm.lastCallGas().gasTotalUsed
        );
    }

    // Confirm that submitting an empty proof passes the mock verifier.
    function test_ValidMockVerifyMembership() public view {
        mockIcs07Tendermint.verifyIcs07MembershipProof(
            mockFixture.proof,
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState,
            new bytes32[](0) // TODO: add kvPairHashes
        );
    }

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockVerifyMembership() public {
        // Invalid proof
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07MembershipProof(
            bytes("invalid"),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState,
            new bytes32[](0) // TODO: add kvPairHashes
        );

        // Invalid proof height
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07MembershipProof(
            bytes(""),
            mockFixture.publicValues,
            1,
            mockFixture.trustedConsensusState,
            new bytes32[](0) // TODO: add kvPairHashes
        );

        // Invalid trusted consensus state
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07MembershipProof(
            bytes(""),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            bytes("invalid"),
            new bytes32[](0) // TODO: add kvPairHashes
        );
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_VerifyMembership() public {
        vm.expectRevert();
        ics07Tendermint.verifyIcs07MembershipProof(
            bytes("invalid"),
            fixture.publicValues,
            fixture.proofHeight,
            fixture.trustedConsensusState,
            new bytes32[](0) // TODO: add kvPairHashes
        );
    }
}
