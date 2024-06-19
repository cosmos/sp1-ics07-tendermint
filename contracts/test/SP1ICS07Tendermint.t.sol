// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1ICS07Tendermint} from "../src/SP1ICS07Tendermint.sol";
import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";

struct SP1ProofFixtureJson {
    uint32 a;
    uint32 b;
    uint32 n;
    bytes proof;
    bytes publicValues;
    bytes32 vkey;
}

contract SP1ICS07TendermintTest is Test {
    using stdJson for string;

    SP1ICS07Tendermint public ics07Tendermint;

    function loadFixture() public view returns (SP1ProofFixtureJson memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/fixtures/fixture.json");
        string memory json = vm.readFile(path);
        bytes memory jsonBytes = json.parseRaw(".");
        return abi.decode(jsonBytes, (SP1ProofFixtureJson));
    }

    // TODO: fix after some rust code
    function setUp() public {
        SP1ProofFixtureJson memory fixture = loadFixture();
        SP1Verifier verifier = new SP1Verifier();
        ics07Tendermint = new SP1ICS07Tendermint(
            fixture.vkey,
            address(verifier)
        );
    }

    function test_ValidSP1ICS07TendermintProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();
        (uint32 n, uint32 a, uint32 b) = ics07Tendermint.verifyIcs07Proof(
            fixture.proof,
            fixture.publicValues
        );
        assert(n == fixture.n);
        assert(a == fixture.a);
        assert(b == fixture.b);
    }

    function testFail_InvalidSP1ICS07TendermintProof() public view {
        SP1ProofFixtureJson memory fixture = loadFixture();

        // Create a fake proof.
        bytes memory fakeProof = new bytes(fixture.proof.length);

        ics07Tendermint.verifyIcs07Proof(fakeProof, fixture.publicValues);
    }
}
