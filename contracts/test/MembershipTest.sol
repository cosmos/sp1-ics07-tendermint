// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";
import { IMembershipMsgs } from "../src/msgs/IMembershipMsgs.sol";

abstract contract MembershipTest is SP1ICS07TendermintTest {
    struct SP1ICS07MembershipFixtureJson {
        MsgMembership membershipMsg;
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
        bytes memory membershipMsgBz = json.readBytes(".membershipMsg");

        SP1ICS07MembershipFixtureJson memory fix = SP1ICS07MembershipFixtureJson({
            membershipMsg: abi.decode(membershipMsgBz, (MsgMembership))
        });

        return fix;
    }
}
