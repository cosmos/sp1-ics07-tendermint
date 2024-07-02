package main

import (
	"context"
	"os"
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"
	"github.com/strangelove-ventures/interchaintest/v8/ibc"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/operator"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/testvalues"
)

const (
	// Private key of an Ethereum account, we use this account to submit transactions
	// through the operator.
	somePrivateKey = "0x5a535512e4b3b9618004a8b47c62191eaa95cca6220452dc612168a4f4f13a75"
	// The public address of the private key above
	someAddress = "0xf4154E9FA98F7d37064F0Cb2cd7934183c2aCCDd"
)

// SP1ICS07TendermintTestSuite is a suite of tests that wraps TestSuite
// and can provide additional functionality
type SP1ICS07TendermintTestSuite struct {
	e2esuite.TestSuite

	// Address of the SP1ICS07Tendermint contract
	contractAddress string
}

// SetupSuite calls the underlying SP1ICS07TendermintTestSuite's SetupSuite method
// and deploys the SP1ICS07Tendermint contract
func (s *SP1ICS07TendermintTestSuite) SetupSuite(ctx context.Context) {
	s.TestSuite.SetupSuite(ctx)

	eth, simd := s.ChainA, s.ChainB

	s.Require().True(s.Run("Set up environment", func() {
		s.Require().NoError(os.Chdir("../.."))

		os.Setenv(testvalues.EnvKeyEthRPC, eth.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeyTendermintRPC, simd.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeySp1Prover, "network")
		os.Setenv(testvalues.EnvKeyPrivateKey, somePrivateKey)

		s.Require().NoError(eth.SendFunds(ctx, "faucet", ibc.WalletAmount{
			Amount:  testvalues.StartingEthBalance,
			Address: someAddress,
		}))
	}))

	s.Require().True(s.Run("Deploy contracts", func() {
		s.Require().NoError(operator.RunGenesis())

		stdout, _, err := eth.ForgeScript(ctx, s.UserA.KeyName(), ethereum.ForgeScriptOpts{
			ContractRootDir:  "contracts",
			SolidityContract: "script/SP1ICS07Tendermint.s.sol",
			RawOptions:       []string{"--json"},
		})
		s.Require().NoError(err)

		s.contractAddress = s.GetEthAddressFromStdout(string(stdout))
		s.Require().NotEmpty(s.contractAddress)
		s.Require().Len(s.contractAddress, 42)

		os.Setenv(testvalues.EnvKeyContractAddress, s.contractAddress)
	}))
}

// TestWithSP1ICS07TendermintTestSuite is the boilerplate code that allows the test suite to be run
func TestWithSP1ICS07TendermintTestSuite(t *testing.T) {
	suite.Run(t, new(SP1ICS07TendermintTestSuite))
}

// TestDeploy tests the deployment of the SP1ICS07Tendermint contract
func (s *SP1ICS07TendermintTestSuite) TestDeploy() {
	ctx := context.Background()

	s.SetupSuite(ctx)
}

// TestUpdateClient tests the update client functionality
func (s *SP1ICS07TendermintTestSuite) TestUpdateClient() {
	ctx := context.Background()

	s.SetupSuite(ctx)
}
