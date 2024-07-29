// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";

abstract contract MembershipTest is SP1ICS07TendermintTest {
    // set constant string
    string public constant VERIFY_MEMBERSHIP_PATH = "clients/07-tendermint-0/clientState";
    string public constant VERIFY_NON_MEMBERSHIP_PATH = "clients/07-tendermint-001/clientState";

    struct SP1ICS07MembershipFixtureJson {
        Height proofHeight;
        MembershipProof membershipProof;
    }

    using stdJson for string;

    SP1ICS07MembershipFixtureJson public fixture;

    function setUpTestWithFixtures(string memory fileName) public {
        fixture = loadFixture(fileName);

        setUpTest(fileName);
    }

    function loadFixture(string memory fileName) public view returns (SP1ICS07MembershipFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory proofHeightBz = json.readBytes(".proofHeight");
        bytes memory membershipProofBz = json.readBytes(".membershipProof");

        SP1ICS07MembershipFixtureJson memory fix = SP1ICS07MembershipFixtureJson({
            proofHeight: abi.decode(proofHeightBz, (Height)),
            membershipProof: abi.decode(membershipProofBz, (MembershipProof))
        });

        return fix;
    }
}
