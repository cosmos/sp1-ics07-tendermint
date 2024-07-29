// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { MembershipTest } from "./MembershipTest.sol";

contract SP1ICS07UpdateClientAndMembershipTest is MembershipTest {
    using stdJson for string;

    SP1MembershipAndUpdateClientProof proof;

    function setUp() public {
        setUpTestWithFixtures("uc_and_memberships_fixture.json");

        proof = abi.decode(fixture.membershipMsg.proof, (SP1MembershipAndUpdateClientProof));

        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));

        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight < output.updateClientOutput.newHeight.revisionHeight);
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClientAndVerifyMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        // run verify
        ics07Tendermint.membership(fixture.membershipMsg);

        // to console
        console.log("UpdateClientAndMultiMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == output.updateClientOutput.newHeight.revisionHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash = ics07Tendermint.getConsensusStateHash(output.updateClientOutput.newHeight.revisionHeight);
        assert(consensusHash == keccak256(abi.encode(output.updateClientOutput.newConsensusState)));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClientAndVerifyNonMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        MsgMembership memory membershipMsg = fixture.membershipMsg;
        membershipMsg.path = bytes(verifyNonMembershipPath);
        membershipMsg.value = bytes("");

        // run verify
        ics07Tendermint.membership(membershipMsg);

        // to console
        console.log("UpdateClientAndMultiMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == output.updateClientOutput.newHeight.revisionHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash = ics07Tendermint.getConsensusStateHash(output.updateClientOutput.newHeight.revisionHeight);
        assert(consensusHash == keccak256(abi.encode(output.updateClientOutput.newConsensusState)));
    }

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockUpdateClient() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(mockKvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(mockKvPairs()[1]));

        vm.expectRevert();
        mockIcs07Tendermint.updateClientAndBatchVerifyMembership(
            bytes("invalid"), fixture.publicValues, kvPairHashes
        );

        // wrong hash
        kvPairHashes[0] = keccak256("random");
        vm.expectRevert();
        mockIcs07Tendermint.updateClientAndBatchVerifyMembership(bytes(""), fixture.publicValues, kvPairHashes);
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_UpdateClient() public {
        bytes32[] memory kvPairHashes = new bytes32[](2);
        kvPairHashes[0] = keccak256(abi.encode(kvPairs()[0]));
        kvPairHashes[1] = keccak256(abi.encode(kvPairs()[1]));

        vm.expectRevert();
        ics07Tendermint.updateClientAndBatchVerifyMembership(bytes("invalid"), fixture.publicValues, kvPairHashes);
    }

    function kvPairs() public view returns (KVPair[] memory) {
        return abi.decode(fixture.kvPairsBz, (KVPair[]));
    }

    function mockKvPairs() public view returns (KVPair[] memory) {
        return abi.decode(fixture.kvPairsBz, (KVPair[]));
    }
}
