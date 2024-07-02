package main

import (
	"context"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/testvalues"
)

// SP1ICS07TendermintTestSuite is a suite of tests that wraps the TestSuite
// and can provide additional functionality
type SP1ICS07TendermintTestSuite struct {
	e2esuite.TestSuite

	// Address of the SP1ICS07Tendermint contract
	contractAddress string
}

// SetupSuite calls the underlying SP1ICS07TendermintTestSuite's SetupSuite method
func (s *SP1ICS07TendermintTestSuite) SetupSuite(ctx context.Context) {
	s.TestSuite.SetupSuite(ctx)
}

// TestWithSP1ICS07TendermintTestSuite is the boilerplate code that allows the test suite to be run
func TestWithSP1ICS07TendermintTestSuite(t *testing.T) {
	suite.Run(t, new(SP1ICS07TendermintTestSuite))
}

// TestBasic is an example test function that will be run by the test suite
func (s *SP1ICS07TendermintTestSuite) TestBasic() {
	ctx := context.Background()

	s.SetupSuite(ctx)

	eth, simd := s.ChainA, s.ChainB

	s.Require().True(s.Run("Deploy contract", func() {
		s.Require().NoError(os.Chdir("../.."))

		os.Setenv(testvalues.EnvKeyEthRPC, eth.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeyTendermintRPC, simd.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeySp1Prover, "network")

		s.Require().NoError(exec.Command("target/release/genesis").Run())

		// TODO: regenerate genesis.json before deploying the contracts
		stdout, _, err := eth.ForgeScript(ctx, s.UserA.KeyName(), ethereum.ForgeScriptOpts{
			ContractRootDir:  "contracts",
			SolidityContract: "script/SP1ICS07Tendermint.s.sol",
			RawOptions:       []string{"--legacy", "--json"},
		})
		s.Require().NoError(err)

		s.contractAddress = s.GetEthAddressFromStdout(string(stdout))
		s.Require().NotEmpty(s.contractAddress)
		s.Require().Len(s.contractAddress, 42)
		s.T().Logf("contract address: %s", s.contractAddress)

		os.Setenv(testvalues.EnvKeyContractAddress, s.contractAddress)
	}))
}
