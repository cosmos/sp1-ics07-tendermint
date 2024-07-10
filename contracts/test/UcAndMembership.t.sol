// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdError} from "forge-std/StdError.sol";
import {ICS07Tendermint} from "../src/ics07-tendermint/ICS07Tendermint.sol";
import {UpdateClientProgram} from "../src/ics07-tendermint/UpdateClientProgram.sol";
import {UpdateClientAndMembershipProgram} from "../src/ics07-tendermint/UcAndMembershipProgram.sol";
import {MembershipProgram} from "../src/ics07-tendermint/MembershipProgram.sol";
import {SP1ICS07TendermintTest} from "./SP1ICS07TendermintTest.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";
import {SP1MockVerifier} from "@sp1-contracts/SP1MockVerifier.sol";

struct SP1ICS07UcAndMemberhsipFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes targetConsensusState;
    uint32 targetHeight;
    bytes publicValues;
    bytes proof;
    bytes kvPairsBz;
}

string constant verifyMembershipPath = "clients/07-tendermint-0/clientState";
string constant verifyNonMembershipPath = "clients/07-tendermint-001/clientState";

contract SP1ICS07UpdateClientAndMembershipTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07UcAndMemberhsipFixtureJson public fixture;
    SP1ICS07UcAndMemberhsipFixtureJson public mockFixture;

    function setUp() public {
        fixture = loadFixture("uc_and_memberships_fixture.json");
        mockFixture = loadFixture("mock_uc_and_memberships_fixture.json");

        setUpTest(
            "uc_and_memberships_fixture.json",
            "mock_uc_and_memberships_fixture.json"
        );

        ICS07Tendermint.ClientState memory clientState = mockIcs07Tendermint
            .getClientState();
        assert(
            clientState.latest_height.revision_height < mockFixture.targetHeight
        );
    }

    function loadFixture(
        string memory fileName
    ) public view returns (SP1ICS07UcAndMemberhsipFixtureJson memory) {
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
        bytes memory publicValues = json.readBytes(".publicValues");
        bytes memory proof = json.readBytes(".proof");
        bytes memory kvPairsBz = json.readBytes(".kvPairs");

        SP1ICS07UcAndMemberhsipFixtureJson
            memory fix = SP1ICS07UcAndMemberhsipFixtureJson({
                trustedClientState: trustedClientState,
                trustedConsensusState: trustedConsensusState,
                targetConsensusState: targetConsensusState,
                targetHeight: targetHeight,
                publicValues: publicValues,
                proof: proof,
                kvPairsBz: kvPairsBz
            });

        return fix;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClientAndMultiMembership() public {
        UpdateClientAndMembershipProgram.UcAndMembershipOutput
            memory output = abi.decode(
                fixture.publicValues,
                (UpdateClientAndMembershipProgram.UcAndMembershipOutput)
            );
        // set a correct timestamp
        vm.warp(output.update_client_output.env.now + 300);

        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(kvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(kvPairs()[1]));

        // run verify
        ics07Tendermint.verifyIcs07UcAndMembershipProof(
            fixture.proof,
            fixture.publicValues,
            kvPairHashes
        );

        // to console
        console.log(
            "UpdateClientAndMultiMembership gas used: ",
            vm.lastCallGas().gasTotalUsed
        );

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

    function test_ValidMockUpdateClientAndMultiMembership() public {
        UpdateClientAndMembershipProgram.UcAndMembershipOutput
            memory output = abi.decode(
                mockFixture.publicValues,
                (UpdateClientAndMembershipProgram.UcAndMembershipOutput)
            );
        vm.warp(output.update_client_output.env.now + 300);

        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));

        mockIcs07Tendermint.verifyIcs07UcAndMembershipProof(
            bytes(""),
            mockFixture.publicValues,
            kvPairHashes
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
            clientState.latest_height.revision_height == fixture.targetHeight
        );
        assert(clientState.trusting_period == 1_209_600);
        assert(clientState.unbonding_period == 1_209_600);
        assert(clientState.is_frozen == false);

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusState(
            mockFixture.targetHeight
        );
        ICS07Tendermint.ConsensusState memory expConsensusState = abi.decode(
            mockFixture.targetConsensusState,
            (ICS07Tendermint.ConsensusState)
        );
        assert(consensusHash == keccak256(abi.encode(expConsensusState)));
    }

    function test_ValidUpdateClientAndVerifyMembership() public {
        UpdateClientAndMembershipProgram.UcAndMembershipOutput
            memory output = abi.decode(
                fixture.publicValues,
                (UpdateClientAndMembershipProgram.UcAndMembershipOutput)
            );
        // set a correct timestamp
        vm.warp(output.update_client_output.env.now + 300);

        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(kvPairs()[0]));
        kvPairHashes[1] = bytes32(0);

        // run verify
        ics07Tendermint.verifyIcs07UcAndMembershipProof(
            fixture.proof,
            fixture.publicValues,
            kvPairHashes
        );

        // to console
        console.log(
            "UpdateClientAndVerifyMembership gas used: ",
            vm.lastCallGas().gasTotalUsed
        );

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

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockUpdateClient() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));

        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07UcAndMembershipProof(
            bytes("invalid"),
            mockFixture.publicValues,
            kvPairHashes
        );

        // wrong hash
        kvPairHashes[0] = keccak256("random");
        vm.expectRevert();
        mockIcs07Tendermint.verifyIcs07UcAndMembershipProof(
            bytes(""),
            mockFixture.publicValues,
            kvPairHashes
        );
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_UpdateClient() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(kvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(kvPairs()[1]));

        vm.expectRevert();
        ics07Tendermint.verifyIcs07UcAndMembershipProof(
            bytes("invalid"),
            fixture.publicValues,
            kvPairHashes
        );
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
}
