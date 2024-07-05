package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/hex"
	"os"
	"testing"

	"github.com/stretchr/testify/suite"

	ethcommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"
	"github.com/strangelove-ventures/interchaintest/v8/ibc"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/operator"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/testvalues"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/types/sp1ics07tendermint"
)

// SP1ICS07TendermintTestSuite is a suite of tests that wraps TestSuite
// and can provide additional functionality
type SP1ICS07TendermintTestSuite struct {
	e2esuite.TestSuite

	// The private key of a test account
	key *ecdsa.PrivateKey
	// The SP1ICS07Tendermint contract
	contract *sp1ics07tendermint.Contract

	// The latest height of client state
	latestHeight uint32
}

// SetupSuite calls the underlying SP1ICS07TendermintTestSuite's SetupSuite method
// and deploys the SP1ICS07Tendermint contract
func (s *SP1ICS07TendermintTestSuite) SetupSuite(ctx context.Context) {
	s.TestSuite.SetupSuite(ctx)

	eth, simd := s.ChainA, s.ChainB

	s.Require().True(s.Run("Set up environment", func() {
		err := os.Chdir("../..")
		s.Require().NoError(err)

		s.key, err = crypto.GenerateKey()
		s.Require().NoError(err)
		hexPrivateKey := hex.EncodeToString(crypto.FromECDSA(s.key))
		address := crypto.PubkeyToAddress(s.key.PublicKey).Hex()
		s.T().Logf("Generated key: %s", address)

		os.Setenv(testvalues.EnvKeyEthRPC, eth.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeyTendermintRPC, simd.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeySp1Prover, "network")
		os.Setenv(testvalues.EnvKeyPrivateKey, hexPrivateKey)
		// make sure that the SP1_PRIVATE_KEY is set.
		s.Require().NotEmpty(os.Getenv(testvalues.EnvKeySp1PrivateKey))

		s.Require().NoError(eth.SendFunds(ctx, "faucet", ibc.WalletAmount{
			Amount:  testvalues.StartingEthBalance,
			Address: address,
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

		contractAddress := s.GetEthAddressFromStdout(string(stdout))
		s.Require().NotEmpty(contractAddress)
		s.Require().Len(contractAddress, 42)
		s.Require().True(ethcommon.IsHexAddress(contractAddress))

		os.Setenv(testvalues.EnvKeyContractAddress, contractAddress)

		client, err := ethclient.Dial(eth.GetHostRPCAddress())
		s.Require().NoError(err)

		s.contract, err = sp1ics07tendermint.NewContract(ethcommon.HexToAddress(contractAddress), client)
		s.Require().NoError(err)
	}))

	s.Require().True(s.Run("Verify deployment", func() {
		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		s.Require().Equal(simd.Config().ChainID, clientState.ChainId)
		s.Require().Equal(uint8(1), clientState.TrustLevel.Numerator)
		s.Require().Equal(uint8(3), clientState.TrustLevel.Denominator)
		s.Require().Equal(uint64(1_209_600_000_000_000), clientState.TrustingPeriod)
		s.Require().Equal(uint64(1_209_600_000_000_000), clientState.UnbondingPeriod)
		s.Require().False(clientState.IsFrozen)
		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, uint32(0))

		s.latestHeight = clientState.LatestHeight.RevisionHeight
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

	_, simd := s.ChainA, s.ChainB

	s.Require().True(s.Run("Update client", func() {
		s.Require().NoError(operator.StartOperator("--only-once"))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		s.Require().Equal(simd.Config().ChainID, clientState.ChainId)
		s.Require().Equal(uint8(1), clientState.TrustLevel.Numerator)
		s.Require().Equal(uint8(3), clientState.TrustLevel.Denominator)
		s.Require().Equal(uint64(1_209_600_000_000_000), clientState.TrustingPeriod)
		s.Require().Equal(uint64(1_209_600_000_000_000), clientState.UnbondingPeriod)
		s.Require().False(clientState.IsFrozen)
		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, s.latestHeight)

		s.latestHeight = clientState.LatestHeight.RevisionHeight
	}))
}
