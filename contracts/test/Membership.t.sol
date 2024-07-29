// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { MembershipTest } from "./MembershipTest.sol";

contract SP1ICS07MembershipTest is MembershipTest {
    using stdJson for string;

    SP1MembershipProof proof;

    function setUp() public {
        setUpTestWithFixtures("memberships_fixture.json");

        proof = abi.decode(fixture.membershipProof.proof, (SP1MembershipProof));
    }

    function test_ValidateFixtures() public view {
        MembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (MembershipOutput));

        assertEq(output.kvPairs.length, 2);
        assertEq(string(output.kvPairs[0].path), verifyMembershipPath);
        assert(output.kvPairs[0].value.length != 0);
        assertEq(string(output.kvPairs[1].path), verifyNonMembershipPath);
        assertEq(output.kvPairs[1].value.length, 0);
    }

    function verifyMembershipValue() public view returns (bytes memory) {
        MembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (MembershipOutput));

        return output.kvPairs[0].value;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidVerifyMembership() public {
        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: bytes(verifyMembershipPath),
            value: verifyMembershipValue()
        });

        ics07Tendermint.membership(membershipMsg);

        // to console
        console.log("VerifyMultiMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // Modify the proof to make it a non-membership proof.
    function test_ValidVerifyNonMembership() public {
        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes("")
        });

        ics07Tendermint.membership(membershipMsg);
        // to console
        console.log("VerifyNonMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // Confirm that submitting an invalid proof with the real verifier fails.
    function test_Invalid_VerifyMembership() public {
        SP1MembershipProof memory proofMsg = proof;
        proofMsg.sp1Proof.proof = bytes("invalid");

        MembershipProof memory membershipProof =
            MembershipProof({ proofType: MembershipProofType.SP1MembershipProof, proof: abi.encode(proofMsg) });

        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(membershipProof),
            proofHeight: fixture.proofHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes("")
        });

        vm.expectRevert();
        ics07Tendermint.membership(membershipMsg);
    }

    function test_Invalid_MockMembership() public {
        MockInvalidMembershipTestCase[] memory testCases = new MockInvalidMembershipTestCase[](7);
        testCases[0] = MockInvalidMembershipTestCase({
            name: "success: valid mock",
            sp1Proof: SP1Proof({ proof: bytes(""), publicValues: proof.sp1Proof.publicValues, vKey: proof.sp1Proof.vKey }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes(""),
            expPass: true
        });
        testCases[1] = MockInvalidMembershipTestCase({
            name: "Invalid proof",
            sp1Proof: SP1Proof({
                proof: bytes("invalid"),
                publicValues: proof.sp1Proof.publicValues,
                vKey: proof.sp1Proof.vKey
            }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes(""),
            expPass: false
        });
        testCases[2] = MockInvalidMembershipTestCase({
            name: "Invalid proof height",
            sp1Proof: SP1Proof({ proof: bytes(""), publicValues: proof.sp1Proof.publicValues, vKey: proof.sp1Proof.vKey }),
            proofHeight: fixture.proofHeight.revisionHeight + 1,
            path: bytes(verifyNonMembershipPath),
            value: bytes(""),
            expPass: false
        });
        testCases[3] = MockInvalidMembershipTestCase({
            name: "Invalid path",
            sp1Proof: SP1Proof({ proof: bytes(""), publicValues: proof.sp1Proof.publicValues, vKey: proof.sp1Proof.vKey }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes("invalid"),
            value: bytes(""),
            expPass: false
        });
        testCases[4] = MockInvalidMembershipTestCase({
            name: "Invalid value",
            sp1Proof: SP1Proof({ proof: bytes(""), publicValues: proof.sp1Proof.publicValues, vKey: proof.sp1Proof.vKey }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes("invalid"),
            expPass: false
        });
        testCases[5] = MockInvalidMembershipTestCase({
            name: "Invalid vKey",
            sp1Proof: SP1Proof({
                proof: bytes(""),
                publicValues: proof.sp1Proof.publicValues,
                vKey: genesisFixture.ucAndMembershipVkey
            }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes(""),
            expPass: false
        });
        testCases[6] = MockInvalidMembershipTestCase({
            name: "Invalid public values",
            sp1Proof: SP1Proof({ proof: bytes(""), publicValues: bytes("invalid"), vKey: proof.sp1Proof.vKey }),
            proofHeight: fixture.proofHeight.revisionHeight,
            path: bytes(verifyNonMembershipPath),
            value: bytes(""),
            expPass: false
        });

        for (uint256 i = 0; i < testCases.length; i++) {
            MockInvalidMembershipTestCase memory tc = testCases[i];

            SP1MembershipProof memory proofMsg = proof;
            proofMsg.sp1Proof = tc.sp1Proof;

            MembershipProof memory membershipProof =
                MembershipProof({ proofType: MembershipProofType.SP1MembershipProof, proof: abi.encode(proofMsg) });

            Height memory proofHeight = fixture.proofHeight;
            proofHeight.revisionHeight = tc.proofHeight;

            MsgMembership memory membershipMsg = MsgMembership({
                proof: abi.encode(membershipProof),
                proofHeight: proofHeight,
                path: tc.path,
                value: tc.value
            });

            if (tc.expPass) {
                mockIcs07Tendermint.membership(membershipMsg);
            } else {
                vm.expectRevert();
                mockIcs07Tendermint.membership(membershipMsg);
            }
        }
    }

    struct MockInvalidMembershipTestCase {
        string name;
        SP1Proof sp1Proof;
        uint32 proofHeight;
        bytes path;
        bytes value;
        bool expPass;
    }
}
