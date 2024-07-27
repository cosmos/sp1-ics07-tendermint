// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { MembershipTest } from "./MembershipTest.sol";

// set constant string
string constant verifyMembershipPath = "clients/07-tendermint-0/clientState";
string constant verifyNonMembershipPath = "clients/07-tendermint-001/clientState";

contract SP1ICS07MultiMembershipTest is MembershipTest {
    using stdJson for string;

    function setUp() public {
        setUpTestWithFixtures("memberships_fixture.json", "mock_memberships_fixture.json");
    }

    function test_ValidateFixtures() public view {
        assertEq(kvPairs().length, 2);
        assertEq(string(kvPairs()[0].path), verifyMembershipPath);
        assert(kvPairs()[0].value.length != 0);
        assertEq(string(kvPairs()[1].path), verifyNonMembershipPath);
        assertEq(kvPairs()[1].value.length, 0);

        assertEq(mockKvPairs().length, 2);
        assertEq(string(mockKvPairs()[0].path), verifyMembershipPath);
        assert(mockKvPairs()[0].value.length != 0);
        assertEq(string(mockKvPairs()[1].path), verifyNonMembershipPath);
        assertEq(mockKvPairs()[1].value.length, 0);
    }

    function test_ValidVerifyNonMembership() public view {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = bytes32(0); // skip validation of the first kvPair
        kvPairHashes[1] = keccak256(abi.encode(kvPairs()[1]));

        ics07Tendermint.batchVerifyMembership(
            fixture.proof, fixture.publicValues, fixture.proofHeight, fixture.trustedConsensusState, kvPairHashes
        );

        // to console
        console.log("VerifyNonMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidMultiMembership() public view {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(kvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(kvPairs()[1]));

        ics07Tendermint.batchVerifyMembership(
            fixture.proof, fixture.publicValues, fixture.proofHeight, fixture.trustedConsensusState, kvPairHashes
        );

        // to console
        console.log("VerifyMultiMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // Confirm that submitting an empty proof passes the mock verifier.
    function test_ValidMockMultiMembership() public view {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));

        mockIcs07Tendermint.batchVerifyMembership(
            bytes(""),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState,
            kvPairHashes
        );
    }

    function test_Invalid_MockMultiMembership() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));
        // Invalid proof
        vm.expectRevert();
        mockIcs07Tendermint.batchVerifyMembership(
            bytes("invalid"),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState,
            kvPairHashes
        );

        // Invalid proof height
        vm.expectRevert();
        mockIcs07Tendermint.batchVerifyMembership(
            bytes(""), mockFixture.publicValues, 1, mockFixture.trustedConsensusState, kvPairHashes
        );

        // Invalid trusted consensus state
        vm.expectRevert();
        mockIcs07Tendermint.batchVerifyMembership(
            bytes(""), mockFixture.publicValues, mockFixture.proofHeight, bytes("invalid"), kvPairHashes
        );

        // Empty kvPairHashes length
        vm.expectRevert();
        mockIcs07Tendermint.batchVerifyMembership(
            bytes(""),
            mockFixture.publicValues,
            mockFixture.proofHeight,
            mockFixture.trustedConsensusState,
            new bytes32[](0)
        );
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_MultiMembership() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));

        vm.expectRevert();
        ics07Tendermint.batchVerifyMembership(
            bytes("invalid"), fixture.publicValues, fixture.proofHeight, fixture.trustedConsensusState, kvPairHashes
        );
    }
}
