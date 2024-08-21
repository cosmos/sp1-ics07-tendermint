// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";
import { IMisbehaviourMsgs } from "../src/msgs/IMisbehaviourMsgs.sol";
import { stdJson } from "forge-std/StdJson.sol";

struct SP1ICS07MisbehaviourFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes submitMsg;
}

contract SP1ICS07MisbehaviourTest is SP1ICS07TendermintTest {
    SP1ICS07MisbehaviourFixtureJson public fixture;

    using stdJson for string;

    function setUp() public {
        fixture = loadFixture("misbehaviour_fixture.json");

        setUpTest("misbehaviour_fixture.json");
    }

    function loadFixture(string memory fileName) public view returns (SP1ICS07MisbehaviourFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(".trustedConsensusState");
        bytes memory submitMsg = json.readBytes(".submitMsg");

        SP1ICS07MisbehaviourFixtureJson memory fix = SP1ICS07MisbehaviourFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            submitMsg: submitMsg
        });

        return fix;
    }

    function test_ValidMisbehaviour() public {
        IMisbehaviourMsgs.MsgSubmitMisbehaviour memory submitMsg =
            abi.decode(fixture.submitMsg, (IMisbehaviourMsgs.MsgSubmitMisbehaviour));
        IMisbehaviourMsgs.MisbehaviourOutput memory output =
            abi.decode(submitMsg.sp1Proof.publicValues, (IMisbehaviourMsgs.MisbehaviourOutput));
        assertTrue(output.isMisbehaviour);

        // TODO: Write the actual test :P
    }
}
