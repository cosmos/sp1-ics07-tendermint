package main

import (
	"context"
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
)

// SP1ICS07TendermintTestSuite is a suite of tests that wraps the TestSuite
// and can provide additional functionality
type SP1ICS07TendermintTestSuite struct {
	e2esuite.TestSuite
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

	eth, _ := s.ChainA, s.ChainB

	s.Require().True(s.Run("Check faucet balance", func() {
		stdout, _, err := eth.ForgeScript(ctx, s.UserA.KeyName(), ethereum.ForgeScriptOpts{
			ContractRootDir:  "../../contracts",
			SolidityContract: "script/SP1ICS07Tendermint.s.sol",
			RawOptions:       []string{"--legacy", "--json"},
		})
		s.Require().NoError(err)

		contractAddr := s.GetEthAddressFromStdout(string(stdout))
		s.Require().NotEmpty(contractAddr)
		s.Require().Len(contractAddr, 42)

		s.T().Logf("contract address: %s", contractAddr)
	}))
}
