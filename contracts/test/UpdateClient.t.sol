// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";

struct SP1ICS07UpdateClientFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes targetConsensusState;
    uint32 targetHeight;
    bytes publicValues;
    bytes proof;
}

contract SP1ICS07UpdateClientTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07UpdateClientFixtureJson public fixture;
    SP1ICS07UpdateClientFixtureJson public mockFixture;

    function setUp() public {
        fixture = loadFixture("update_client_fixture.json");
        mockFixture = loadFixture("mock_update_client_fixture.json");

        setUpTest("update_client_fixture.json", "mock_update_client_fixture.json");

        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight < mockFixture.targetHeight);

        assert(mockIcs07Tendermint.getConsensusStateHash(mockFixture.targetHeight) == bytes32(0));
    }

    function loadFixture(string memory fileName) public view returns (SP1ICS07UpdateClientFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(".trustedConsensusState");
        bytes memory targetConsensusState = json.readBytes(".targetConsensusState");
        uint32 targetHeight = uint32(json.readUint(".targetHeight"));
        bytes memory publicValues = json.readBytes(".publicValues");
        bytes memory proof = json.readBytes(".proof");

        SP1ICS07UpdateClientFixtureJson memory fix = SP1ICS07UpdateClientFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            targetConsensusState: targetConsensusState,
            targetHeight: targetHeight,
            publicValues: publicValues,
            proof: proof
        });

        return fix;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidUpdateClient() public {
        // set a correct timestamp
        UpdateClientOutput memory output = abi.decode(fixture.publicValues, (UpdateClientOutput));
        vm.warp(output.env.now + 300);

        // run verify
        UpdateResult res = ics07Tendermint.updateClient(fixture.proof, fixture.publicValues);

        // to console
        console.log("UpdateClient gas used: ", vm.lastCallGas().gasTotalUsed);
        assert(res == UpdateResult.Update);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(keccak256(bytes(clientState.chainId)) == keccak256(bytes("mocha-4")));
        assert(clientState.latestHeight.revisionHeight == fixture.targetHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash = ics07Tendermint.getConsensusStateHash(fixture.targetHeight);
        ConsensusState memory expConsensusState = abi.decode(fixture.targetConsensusState, (ConsensusState));
        assert(consensusHash == keccak256(abi.encode(expConsensusState)));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_ValidNoOpUpdateClient() public {
        // set a correct timestamp
        UpdateClientOutput memory output = abi.decode(fixture.publicValues, (UpdateClientOutput));
        vm.warp(output.env.now + 300);

        // run verify
        UpdateResult res = ics07Tendermint.updateClient(fixture.proof, fixture.publicValues);
        assert(res == UpdateResult.Update);

        // run verify again
        res = ics07Tendermint.updateClient(fixture.proof, fixture.publicValues);

        // to console
        console.log("UpdateClient_NoOp gas used: ", vm.lastCallGas().gasTotalUsed);
        assert(res == UpdateResult.NoOp);
    }

    // Confirm that submitting an empty proof passes the mock verifier.
    function test_ValidMockUpdateClient() public {
        // set a correct timestamp
        UpdateClientOutput memory output = abi.decode(mockFixture.publicValues, (UpdateClientOutput));
        vm.warp(output.env.now + 300);

        // run verify
        UpdateResult res = mockIcs07Tendermint.updateClient(bytes(""), mockFixture.publicValues);

        assert(res == UpdateResult.Update);
        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == mockFixture.targetHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusStateHash(mockFixture.targetHeight);
        ConsensusState memory expConsensusState = abi.decode(fixture.targetConsensusState, (ConsensusState));
        assert(consensusHash == keccak256(abi.encode(expConsensusState)));
    }

    // Confirm that submitting a non-empty proof with the mock verifier fails.
    function test_Invalid_MockUpdateClient() public {
        vm.expectRevert();
        mockIcs07Tendermint.updateClient(bytes("invalid"), mockFixture.publicValues);
    }

    // Confirm that submitting a random proof with the real verifier fails.
    function test_Invalid_UpdateClient() public {
        vm.expectRevert();
        ics07Tendermint.updateClient(bytes("invalid"), fixture.publicValues);
    }
}
