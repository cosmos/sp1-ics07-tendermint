// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { MembershipTest } from "./MembershipTest.sol";

contract UnionMembershipTest is MembershipTest {
    UnionMembershipProof public proof;

    function setUp() public {
        setUpTestWithFixtures("union_membership_fixture.json");

        proof = abi.decode(fixture.membershipProof.proof, (UnionMembershipProof));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUnionVerifyMembership() public {
        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyMembershipPath,
            value: VERIFY_MEMBERSHIP_VALUE
        });

        ics07Tendermint.membership(membershipMsg);

        console.log("UnionVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }
}

contract UnionNonMembershipTest is MembershipTest {
    UnionMembershipProof public proof;

    function setUp() public {
        setUpTestWithFixtures("union_nonmembership_fixture.json");

        proof = abi.decode(fixture.membershipProof.proof, (UnionMembershipProof));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUnionVerifyNonMembership() public {
        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyNonMembershipPath,
            value: bytes("")
        });

        ics07Tendermint.membership(membershipMsg);

        console.log("UnionVerifyNonMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }
}
