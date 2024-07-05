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

contract SP1ICS07TendermintTest is Test {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;
    SP1ICS07Tendermint public mockIcs07Tendermint;

    SP1ICS07VerifyMembershipFixtureJson public fixture;
    SP1ICS07VerifyMembershipFixtureJson public mockFixture;

    function setUp() public {
        fixture = loadFixture("verify_membership_fixture.json");

        ICS07Tendermint.ConsensusState memory trustedConsensusState = abi
            .decode(
                fixture.trustedConsensusState,
                (ICS07Tendermint.ConsensusState)
            );

        bytes32 trustedConsensusHash = keccak256(
            abi.encode(trustedConsensusState)
        );

        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            fixture.updateClientVkey,
            fixture.verifyMembershipVkey,
            address(verifier),
            fixture.trustedClientState,
            trustedConsensusHash
        );

        mockFixture = loadFixture("mock_verify_membership_fixture.json");

        ICS07Tendermint.ConsensusState memory mockTrustedConsensusState = abi
            .decode(
                mockFixture.trustedConsensusState,
                (ICS07Tendermint.ConsensusState)
            );

        bytes32 mockTrustedConsensusHash = keccak256(
            abi.encode(mockTrustedConsensusState)
        );

        SP1MockVerifier mockVerifier = new SP1MockVerifier();
        mockIcs07Tendermint = new SP1ICS07Tendermint(
            mockFixture.updateClientVkey,
            mockFixture.verifyMembershipVkey,
            address(mockVerifier),
            mockFixture.trustedClientState,
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
        assert(clientState.trusting_period == 1_209_600_000_000_000);
        assert(clientState.unbonding_period == 1_209_600_000_000_000);
        assert(clientState.is_frozen == false);

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusState(2110658);
        assert(consensusHash == trustedConsensusHash);
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
        ics07Tendermint.verifyIcs07VerifyMembershipProof(
            fixture.proof,
            fixture.publicValues,
            fixture.proofHeight,
            fixture.trustedConsensusState
        );
    }

    // Confirm that submitting an empty proof passes the mock verifier.
    function test_ValidMockVerifyMembership() public view {
        mockIcs07Tendermint.verifyIcs07VerifyMembershipProof(
            mockFixture.proof,
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState
        );
    }

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockVerifyMembership() public {
        // Invalid proof
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07VerifyMembershipProof(
            bytes("invalid"),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState
        );

        // Invalid proof height
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07VerifyMembershipProof(
            bytes(""),
            mockFixture.publicValues,
            1,
            mockFixture.trustedConsensusState
        );

        // Invalid trusted consensus state
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07VerifyMembershipProof(
            bytes(""),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            bytes("invalid")
        );
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_VerifyMembership() public {
        vm.expectRevert();
        ics07Tendermint.verifyIcs07VerifyMembershipProof(
            bytes("invalid"),
            fixture.publicValues,
            fixture.proofHeight,
            fixture.trustedConsensusState
        );
    }
}
