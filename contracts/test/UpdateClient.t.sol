// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";

struct SP1ICS07UpdateClientFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes updateMsg;
}

contract SP1ICS07UpdateClientTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07UpdateClientFixtureJson public fixture;

    uint32 public targetHeight;
    ConsensusState public targetConsensusState;
    Env public env;

    function setUp() public {
        fixture = loadFixture("update_client_fixture.json");

        setUpTest("update_client_fixture.json");

        MsgUpdateClient memory updateMsg = abi.decode(fixture.updateMsg, (MsgUpdateClient));
        UpdateClientOutput memory output = abi.decode(updateMsg.sp1Proof.publicValues, (UpdateClientOutput));
        targetHeight = output.newHeight.revisionHeight;
        targetConsensusState = output.newConsensusState;
        env = output.env;

        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight < targetHeight);

        vm.expectRevert();
        mockIcs07Tendermint.getConsensusStateHash(targetHeight);
    }

    function loadFixture(string memory fileName) public view returns (SP1ICS07UpdateClientFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(".trustedConsensusState");
        bytes memory updateMsg = json.readBytes(".updateMsg");

        SP1ICS07UpdateClientFixtureJson memory fix = SP1ICS07UpdateClientFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            updateMsg: updateMsg
        });

        return fix;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClient() public {
        // set a correct timestamp
        vm.warp(env.now + 300);

        // run verify
        UpdateResult res = ics07Tendermint.updateClient(fixture.updateMsg);

        // to console
        console.log("UpdateClient gas used: ", vm.lastCallGas().gasTotalUsed);
        assert(res == UpdateResult.Update);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(keccak256(bytes(clientState.chainId)) == keccak256(bytes("mocha-4")));
        assert(clientState.latestHeight.revisionHeight == targetHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash = ics07Tendermint.getConsensusStateHash(targetHeight);
        assert(consensusHash == keccak256(abi.encode(targetConsensusState)));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidNoOpUpdateClient() public {
        // set a correct timestamp
        vm.warp(env.now + 300);

        // run verify
        UpdateResult res = ics07Tendermint.updateClient(fixture.updateMsg);
        assert(res == UpdateResult.Update);

        // run verify again
        res = ics07Tendermint.updateClient(fixture.updateMsg);

        // to console
        console.log("UpdateClient_NoOp gas used: ", vm.lastCallGas().gasTotalUsed);
        assert(res == UpdateResult.NoOp);
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_UpdateClient() public {
        vm.expectRevert();
        ics07Tendermint.updateClient(bytes("invalid"));
    }
}
