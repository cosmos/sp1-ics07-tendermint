// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { SP1ICS07Tendermint } from "../src/SP1ICS07Tendermint.sol";
import { SP1ICS07TendermintTest } from "./SP1ICS07TendermintTest.sol";
import { IMisbehaviourMsgs } from "../src/msgs/IMisbehaviourMsgs.sol";
import { SP1Verifier } from "@sp1-contracts/v3.0.0/SP1VerifierPlonk.sol";
import { stdJson } from "forge-std/StdJson.sol";

struct SP1ICS07MisbehaviourFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes submitMsg;
}

contract SP1ICS07MisbehaviourTest is SP1ICS07TendermintTest {
    using stdJson for string;

    SP1ICS07MisbehaviourFixtureJson public fixture;
    MsgSubmitMisbehaviour public submitMsg;
    MisbehaviourOutput public output;

    function setUpMisbehaviour(string memory fileName) public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientStateBz = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusStateBz = json.readBytes(".trustedConsensusState");
        bytes memory submitMsgBz = json.readBytes(".submitMsg");

        fixture = SP1ICS07MisbehaviourFixtureJson({
            trustedClientState: trustedClientStateBz,
            trustedConsensusState: trustedConsensusStateBz,
            submitMsg: submitMsgBz
        });

        setUpTest(fileName);

        submitMsg = abi.decode(fixture.submitMsg, (IMisbehaviourMsgs.MsgSubmitMisbehaviour));
        output = abi.decode(submitMsg.sp1Proof.publicValues, (IMisbehaviourMsgs.MisbehaviourOutput));
    }

    function test_ValidDoubleSignMisbehaviour() public {
        setUpMisbehaviour("misbehaviour_double_sign_fixture.json");

        // set a correct timestamp
        vm.warp(output.time);
        ics07Tendermint.misbehaviour(fixture.submitMsg);

        // to console
        console.log("Misbehaviour gas used: ", vm.lastCallGas().gasTotalUsed);

        // verify that the client is frozen
        ClientState memory clientState = ics07Tendermint.getClientState();
        assertTrue(clientState.isFrozen);
    }

    function test_ValidBreakingTimeMonotonicityMisbehaviour() public {
        setUpMisbehaviour("misbehaviour_breaking_time_monotonicity_fixture.json");

        // set a correct timestamp
        vm.warp(output.time);
        ics07Tendermint.misbehaviour(fixture.submitMsg);

        // to console
        console.log("Misbehaviour gas used: ", vm.lastCallGas().gasTotalUsed);

        // verify that the client is frozen
        ClientState memory clientState = ics07Tendermint.getClientState();
        assertTrue(clientState.isFrozen);
    }

    function test_InvalidMisbehaviour() public {
        setUpMisbehaviour("misbehaviour_double_sign_fixture.json");

        // proof is in the future
        vm.warp(output.time - 300);
        vm.expectRevert(abi.encodeWithSelector(ProofIsInTheFuture.selector, block.timestamp, output.time));
        ics07Tendermint.misbehaviour(fixture.submitMsg);

        // proof is too old
        vm.warp(output.time + ics07Tendermint.ALLOWED_SP1_CLOCK_DRIFT() + 300);
        vm.expectRevert(abi.encodeWithSelector(ProofIsTooOld.selector, block.timestamp, output.time));
        ics07Tendermint.misbehaviour(fixture.submitMsg);

        // set a correct timestamp
        vm.warp(output.time + 300);

        // wrong vkey
        MsgSubmitMisbehaviour memory badSubmitMsg = cloneSubmitMsg();
        badSubmitMsg.sp1Proof.vKey = bytes32(0);
        bytes memory submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(
            abi.encodeWithSelector(
                VerificationKeyMismatch.selector,
                ics07Tendermint.MISBEHAVIOUR_PROGRAM_VKEY(),
                badSubmitMsg.sp1Proof.vKey
            )
        );
        ics07Tendermint.misbehaviour(submitMsgBz);

        // chain id mismatch
        badSubmitMsg = cloneSubmitMsg();
        MisbehaviourOutput memory badOutput = cloneOutput();
        badOutput.clientState.chainId = "bad-chain-id";
        badSubmitMsg.sp1Proof.publicValues = abi.encode(badOutput);
        submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(abi.encodeWithSelector(ChainIdMismatch.selector, output.clientState.chainId, badOutput.clientState.chainId));
        ics07Tendermint.misbehaviour(submitMsgBz);

        // trust threshold mismatch
        badSubmitMsg = cloneSubmitMsg();
        badOutput = cloneOutput();
        badOutput.clientState.trustLevel = TrustThreshold({ numerator: 1, denominator: 2 });
        badSubmitMsg.sp1Proof.publicValues = abi.encode(badOutput);
        submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(
            abi.encodeWithSelector(
                TrustThresholdMismatch.selector, output.clientState.trustLevel, badOutput.clientState.trustLevel
            )
        );
        ics07Tendermint.misbehaviour(submitMsgBz);

        // trusting period mismatch
        badSubmitMsg = cloneSubmitMsg();
        badOutput = cloneOutput();
        badOutput.clientState.trustingPeriod = 1;
        badSubmitMsg.sp1Proof.publicValues = abi.encode(badOutput);
        submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(
            abi.encodeWithSelector(
                TrustingPeriodMismatch.selector, output.clientState.trustingPeriod, badOutput.clientState.trustingPeriod
            )
        );
        ics07Tendermint.misbehaviour(submitMsgBz);

        // trusting period too long
        // we need to set up a new misconfigured client where the trusting period is longer than the unbonding period
        ClientState memory clientState = ics07Tendermint.getClientState();
        ClientState memory badClientState = ClientState({
            chainId: clientState.chainId,
            trustLevel: clientState.trustLevel,
            latestHeight: clientState.latestHeight,
            trustingPeriod: clientState.unbondingPeriod + 1,
            unbondingPeriod: clientState.unbondingPeriod,
            isFrozen: clientState.isFrozen
        });
        bytes32 trustedConsensusState = ics07Tendermint.getConsensusStateHash(clientState.latestHeight.revisionHeight);
        SP1ICS07Tendermint badClient = new SP1ICS07Tendermint(
            ics07Tendermint.UPDATE_CLIENT_PROGRAM_VKEY(),
            ics07Tendermint.MEMBERSHIP_PROGRAM_VKEY(),
            ics07Tendermint.UPDATE_CLIENT_AND_MEMBERSHIP_PROGRAM_VKEY(),
            ics07Tendermint.MISBEHAVIOUR_PROGRAM_VKEY(),
            address(ics07Tendermint.VERIFIER()),
            abi.encode(badClientState),
            trustedConsensusState
        );
        badOutput = cloneOutput();
        badOutput.clientState.trustingPeriod = badClientState.trustingPeriod;
        badSubmitMsg = cloneSubmitMsg();
        badSubmitMsg.sp1Proof.publicValues = abi.encode(badOutput);
        submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(
            abi.encodeWithSelector(
                TrustingPeriodTooLong.selector, badClientState.trustingPeriod, badClientState.unbondingPeriod
            )
        );
        badClient.misbehaviour(submitMsgBz);

        // invalid proof
        badSubmitMsg = cloneSubmitMsg();
        badOutput = cloneOutput();
        badOutput.time = badOutput.time + 1;
        badSubmitMsg.sp1Proof.publicValues = abi.encode(badOutput);
        submitMsgBz = abi.encode(badSubmitMsg);
        vm.expectRevert(abi.encodeWithSelector(SP1Verifier.InvalidProof.selector));
        ics07Tendermint.misbehaviour(submitMsgBz);

        // client state is frozen
        ics07Tendermint.misbehaviour(fixture.submitMsg); // freeze the client
        vm.expectRevert(abi.encodeWithSelector(FrozenClientState.selector));
        ics07Tendermint.misbehaviour(fixture.submitMsg);
    }

    function cloneSubmitMsg() private view returns (MsgSubmitMisbehaviour memory) {
        MsgSubmitMisbehaviour memory clone = MsgSubmitMisbehaviour({
            sp1Proof: SP1Proof({
                vKey: submitMsg.sp1Proof.vKey,
                publicValues: submitMsg.sp1Proof.publicValues,
                proof: submitMsg.sp1Proof.proof
            })
        });
        return clone;
    }

    function cloneOutput() private view returns (MisbehaviourOutput memory) {
        MisbehaviourOutput memory clone = MisbehaviourOutput({
            clientState: output.clientState,
            time: output.time,
            trustedHeight1: output.trustedHeight1,
            trustedHeight2: output.trustedHeight2,
            trustedConsensusState1: output.trustedConsensusState1,
            trustedConsensusState2: output.trustedConsensusState2
        });
        return clone;
    }
}
