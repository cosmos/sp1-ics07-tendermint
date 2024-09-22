// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { IICS07TendermintMsgs } from "../src/msgs/IICS07TendermintMsgs.sol";
import { IUpdateClientMsgs } from "../src/msgs/IUpdateClientMsgs.sol";
import { IMembershipMsgs } from "../src/msgs/IMembershipMsgs.sol";
import { IUpdateClientAndMembershipMsgs } from "../src/msgs/IUcAndMembershipMsgs.sol";
import { IMisbehaviourMsgs } from "../src/msgs/IMisbehaviourMsgs.sol";
import { SP1ICS07Tendermint } from "../src/SP1ICS07Tendermint.sol";
import { ISP1ICS07TendermintErrors } from "../src/errors/ISP1ICS07TendermintErrors.sol";
import { SP1Verifier } from "@sp1-contracts/v2.0.0/SP1VerifierPlonk.sol";
import { SP1MockVerifier } from "@sp1-contracts/SP1MockVerifier.sol";
import { ILightClientMsgs } from "solidity-ibc/msgs/ILightClientMsgs.sol";

struct SP1ICS07GenesisFixtureJson {
    bytes trustedClientState;
    bytes trustedConsensusState;
    bytes32 updateClientVkey;
    bytes32 membershipVkey;
    bytes32 ucAndMembershipVkey;
    bytes32 misbehaviourVkey;
}

abstract contract SP1ICS07TendermintTest is
    Test,
    IICS07TendermintMsgs,
    IUpdateClientMsgs,
    IMembershipMsgs,
    IUpdateClientAndMembershipMsgs,
    IMisbehaviourMsgs,
    ISP1ICS07TendermintErrors,
    ILightClientMsgs
{
    using stdJson for string;

    SP1Verifier public verifier;

    SP1ICS07Tendermint public ics07Tendermint;
    SP1ICS07Tendermint public mockIcs07Tendermint;

    SP1ICS07GenesisFixtureJson internal genesisFixture;

    function setUpTest(string memory fileName) public {
        genesisFixture = loadGenesisFixture(fileName);

        ConsensusState memory trustedConsensusState = abi.decode(genesisFixture.trustedConsensusState, (ConsensusState));

        bytes32 trustedConsensusHash = keccak256(abi.encode(trustedConsensusState));

        verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            genesisFixture.updateClientVkey,
            genesisFixture.membershipVkey,
            genesisFixture.ucAndMembershipVkey,
            genesisFixture.misbehaviourVkey,
            address(verifier),
            genesisFixture.trustedClientState,
            trustedConsensusHash
        );

        SP1MockVerifier mockVerifier = new SP1MockVerifier();
        mockIcs07Tendermint = new SP1ICS07Tendermint(
            genesisFixture.updateClientVkey,
            genesisFixture.membershipVkey,
            genesisFixture.ucAndMembershipVkey,
            genesisFixture.misbehaviourVkey,
            address(mockVerifier),
            genesisFixture.trustedClientState,
            trustedConsensusHash
        );

        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(keccak256(abi.encode(clientState)) == keccak256(genesisFixture.trustedClientState));

        bytes32 consensusHash = mockIcs07Tendermint.getConsensusStateHash(clientState.latestHeight.revisionHeight);
        assert(consensusHash == trustedConsensusHash);
    }

    function loadGenesisFixture(string memory fileName) public view returns (SP1ICS07GenesisFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/contracts/fixtures/", fileName);
        string memory json = vm.readFile(path);
        bytes memory trustedClientState = json.readBytes(".trustedClientState");
        bytes memory trustedConsensusState = json.readBytes(".trustedConsensusState");
        bytes32 updateClientVkey = json.readBytes32(".updateClientVkey");
        bytes32 membershipVkey = json.readBytes32(".membershipVkey");
        bytes32 ucAndMembershipVkey = json.readBytes32(".ucAndMembershipVkey");
        bytes32 misbehaviourVkey = json.readBytes32(".misbehaviourVkey");

        SP1ICS07GenesisFixtureJson memory fix = SP1ICS07GenesisFixtureJson({
            trustedClientState: trustedClientState,
            trustedConsensusState: trustedConsensusState,
            updateClientVkey: updateClientVkey,
            membershipVkey: membershipVkey,
            ucAndMembershipVkey: ucAndMembershipVkey,
            misbehaviourVkey: misbehaviourVkey
        });

        return fix;
    }
}
