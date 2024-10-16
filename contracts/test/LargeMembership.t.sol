// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { MembershipTest } from "./MembershipTest.sol";

contract SP1ICS07LargeMembershipTest is MembershipTest {
    SP1MembershipProof public proof;

    function setUp() public {
        setUpTestWithFixtures("membership_25_fixture.json");

        proof = abi.decode(fixture.membershipProof.proof, (SP1MembershipProof));
    }

    function test_ValidateFixtures() public view {
        MembershipOutput memory output = getOutput();

        assertEq(output.kvPairs.length, 100);
    }

    function getOutput() public view returns (MembershipOutput memory) {
        return abi.decode(proof.sp1Proof.publicValues, (MembershipOutput));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidLargeVerifyMembership() public {
        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: getOutput().kvPairs[0].path,
            value: getOutput().kvPairs[0].value
        });

        ics07Tendermint.membership(membershipMsg);

        console.log("LargeVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        ics07Tendermint.membership(membershipMsg);

        console.log("Cached LargeVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // function test_ValidCachedMembership() public {
    //     MsgMembership memory membershipMsg = MsgMembership({
    //         proof: abi.encode(fixture.membershipProof),
    //         proofHeight: fixture.proofHeight,
    //         path: verifyMembershipPath,
    //         value: verifyMembershipValue()
    //     });
    //
    //     ics07Tendermint.membership(membershipMsg);
    //
    //     // resubmit the same proof
    //     ics07Tendermint.membership(membershipMsg);
    //
    //     console.log("Cached VerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    // }
}
