package main

import (
	"context"
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
)

// BasicTestSuite is a suite of tests that wraps the TestSuite
// and can provide additional functionality
type BasicTestSuite struct {
	e2esuite.TestSuite
}

// SetupSuite calls the underlying BasicTestSuite's SetupSuite method
func (s *BasicTestSuite) SetupSuite(ctx context.Context) {
	s.TestSuite.SetupSuite(ctx)
}

// TestWithBasicTestSuite is the boilerplate code that allows the test suite to be run
func TestWithBasicTestSuite(t *testing.T) {
	suite.Run(t, new(BasicTestSuite))
}

// TestBasic is an example test function that will be run by the test suite
func (s *BasicTestSuite) TestBasic() {
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
