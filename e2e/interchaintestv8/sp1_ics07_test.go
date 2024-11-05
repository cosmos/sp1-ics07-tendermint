package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/hex"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/suite"

	ethcommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"

	abci "github.com/cometbft/cometbft/abci/types"

	transfertypes "github.com/cosmos/ibc-go/v8/modules/apps/transfer/types"
	ibcclientutils "github.com/cosmos/ibc-go/v8/modules/core/02-client/client/utils"
	clienttypes "github.com/cosmos/ibc-go/v8/modules/core/02-client/types"
	ibchost "github.com/cosmos/ibc-go/v8/modules/core/24-host"
	ibcexported "github.com/cosmos/ibc-go/v8/modules/core/exported"
	tmclient "github.com/cosmos/ibc-go/v8/modules/light-clients/07-tendermint"
	ibctesting "github.com/cosmos/ibc-go/v8/testing"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum/foundry"
	"github.com/strangelove-ventures/interchaintest/v8/ibc"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/operator"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/testvalues"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/types"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/types/sp1ics07tendermint"
)

// SP1ICS07TendermintTestSuite is a suite of tests that wraps TestSuite
// and can provide additional functionality
type SP1ICS07TendermintTestSuite struct {
	e2esuite.TestSuite

	// Whether to generate fixtures for the solidity tests
	generateFixtures bool

	// The private key of a test account
	key *ecdsa.PrivateKey
	// The SP1ICS07Tendermint contract
	contract *sp1ics07tendermint.Contract
}

// SetupSuite calls the underlying SP1ICS07TendermintTestSuite's SetupSuite method
// and deploys the SP1ICS07Tendermint contract
func (s *SP1ICS07TendermintTestSuite) SetupSuite(ctx context.Context, opArgs ...string) {
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

		os.Setenv(testvalues.EnvKeyRustLog, testvalues.EnvValueRustLog_Info)
		os.Setenv(testvalues.EnvKeyEthRPC, eth.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeyTendermintRPC, simd.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeySp1Prover, "network")
		os.Setenv(testvalues.EnvKeyPrivateKey, hexPrivateKey)
		s.generateFixtures = os.Getenv(testvalues.EnvKeyGenerateFixtures) == testvalues.EnvValueGenerateFixtures_True

		// make sure that the SP1_PRIVATE_KEY is set.
		s.Require().NotEmpty(os.Getenv(testvalues.EnvKeySp1PrivateKey))

		s.Require().NoError(eth.SendFunds(ctx, "faucet", ibc.WalletAmount{
			Amount:  testvalues.StartingEthBalance,
			Address: address,
		}))
	}))

	s.Require().True(s.Run("Deploy contracts", func() {
		args := append([]string{
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
			"-o", "contracts/script/genesis.json",
		}, opArgs...)
		s.Require().NoError(operator.RunGenesis(args...))

		s.T().Cleanup(func() {
			err := os.Remove("contracts/script/genesis.json")
			s.Require().NoError(err)
		})

		stdout, _, err := eth.ForgeScript(ctx, s.UserA.KeyName(), foundry.ForgeScriptOpts{
			ContractRootDir:  ".",
			SolidityContract: "contracts/script/SP1ICS07Tendermint.s.sol",
			RawOptions:       []string{"--json"},
		})
		s.Require().NoError(err)

		contractAddress := s.GetEthAddressFromStdout(string(stdout))
		s.Require().NotEmpty(contractAddress)
		s.Require().True(ethcommon.IsHexAddress(contractAddress))

		os.Setenv(testvalues.EnvKeyContractAddress, contractAddress)

		client, err := ethclient.Dial(eth.GetHostRPCAddress())
		s.Require().NoError(err)

		s.contract, err = sp1ics07tendermint.NewContract(ethcommon.HexToAddress(contractAddress), client)
		s.Require().NoError(err)
	}))
}

// TestWithSP1ICS07TendermintTestSuite is the boilerplate code that allows the test suite to be run
func TestWithSP1ICS07TendermintTestSuite(t *testing.T) {
	suite.Run(t, new(SP1ICS07TendermintTestSuite))
}

func (s *SP1ICS07TendermintTestSuite) TestDeploy_Groth16() {
	ctx := context.Background()
	s.DeployTest(ctx, "-p", "groth16")
}

func (s *SP1ICS07TendermintTestSuite) TestDeploy_Plonk() {
	ctx := context.Background()
	s.DeployTest(ctx, "-p", "plonk")
}

// DeployTest tests the deployment of the SP1ICS07Tendermint contract with the given arguments
func (s *SP1ICS07TendermintTestSuite) DeployTest(ctx context.Context, opArgs ...string) {
	s.SetupSuite(ctx, opArgs...)

	_, simd := s.ChainA, s.ChainB

	s.Require().True(s.Run("Verify deployment", func() {
		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		stakingParams, err := simd.StakingQueryParams(ctx)
		s.Require().NoError(err)

		s.Require().Equal(simd.Config().ChainID, clientState.ChainId)
		s.Require().Equal(uint8(testvalues.DefaultTrustLevel.Numerator), clientState.TrustLevel.Numerator)
		s.Require().Equal(uint8(testvalues.DefaultTrustLevel.Denominator), clientState.TrustLevel.Denominator)
		s.Require().Equal(uint32(testvalues.DefaultTrustPeriod), clientState.TrustingPeriod)
		s.Require().Equal(uint32(stakingParams.UnbondingTime.Seconds()), clientState.UnbondingPeriod)
		s.Require().False(clientState.IsFrozen)
		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, uint32(0))
	}))
}

func (s *SP1ICS07TendermintTestSuite) TestUpdateClient_Groth16() {
	ctx := context.Background()
	s.UpdateClientTest(ctx, "-p", "groth16")
}

func (s *SP1ICS07TendermintTestSuite) TestUpdateClient_Plonk() {
	ctx := context.Background()
	s.UpdateClientTest(ctx, "-p", "plonk")
}

// UpdateClientTest tests the update client functionality
func (s *SP1ICS07TendermintTestSuite) UpdateClientTest(ctx context.Context, opArgs ...string) {
	s.SetupSuite(ctx, opArgs...)

	_, simd := s.ChainA, s.ChainB

	if s.generateFixtures {
		s.T().Log("Generate fixtures is set to true, but TestUpdateClient does not support it (yet)")
	}

	s.Require().True(s.Run("Update client", func() {
		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		initialHeight := clientState.LatestHeight.RevisionHeight

		s.Require().NoError(operator.StartOperator("--only-once")) // This should detect the proof type

		clientState, err = s.contract.GetClientState(nil)
		s.Require().NoError(err)

		stakingParams, err := simd.StakingQueryParams(ctx)
		s.Require().NoError(err)

		s.Require().Equal(simd.Config().ChainID, clientState.ChainId)
		s.Require().Equal(uint8(testvalues.DefaultTrustLevel.Numerator), clientState.TrustLevel.Numerator)
		s.Require().Equal(uint8(testvalues.DefaultTrustLevel.Denominator), clientState.TrustLevel.Denominator)
		s.Require().Equal(uint32(testvalues.DefaultTrustPeriod), clientState.TrustingPeriod)
		s.Require().Equal(uint32(stakingParams.UnbondingTime.Seconds()), clientState.UnbondingPeriod)
		s.Require().False(clientState.IsFrozen)
		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, initialHeight)
	}))
}

// TestUnionMembership tests the verify (non)membership functionality with the --union flag
func (s *SP1ICS07TendermintTestSuite) TestMembership_Union() {
	s.MembershipTest("-p", "union")
}

// TestSP1Membership tests the verify (non)membership functionality with the plonk flag
func (s *SP1ICS07TendermintTestSuite) TestMembership_Plonk() {
	s.MembershipTest("-p", "plonk")
}

// TestSP1Membership tests the verify (non)membership functionality with the plonk flag
func (s *SP1ICS07TendermintTestSuite) TestMembership_Groth16() {
	s.MembershipTest("-p", "groth16")
}

// MembershipTest tests the verify (non)membership functionality with the given arguments
func (s *SP1ICS07TendermintTestSuite) MembershipTest(args ...string) {
	ctx := context.Background()

	s.SetupSuite(ctx, args...)

	eth, simd := s.ChainA, s.ChainB

	if s.generateFixtures {
		s.T().Log("Generate fixtures is set to true, but TestVerifyMembership does not support it (yet)")
	}

	s.Require().True(s.Run("Verify membership", func() {
		var membershipKey [][]byte
		s.Require().True(s.Run("Generate keys", func() {
			// Prove the bank balance of UserA
			key, err := types.BankBalanceKey(s.UserB.Address(), simd.Config().Denom)
			s.Require().NoError(err)

			membershipKey = [][]byte{[]byte(banktypes.StoreKey), key}
		}))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		trustedHeight := clientState.LatestHeight.RevisionHeight

		var expValue []byte
		s.Require().True(s.Run("Get expected value for the verify membership", func() {
			resp, err := e2esuite.ABCIQuery(ctx, simd, &abci.RequestQuery{
				Path:   "store/" + string(membershipKey[0]) + "/key",
				Data:   membershipKey[1],
				Height: int64(trustedHeight) - 1,
			})
			s.Require().NoError(err)
			s.Require().NotEmpty(resp.Value)

			expValue = resp.Value
		}))

		memArgs := append([]string{"--trust-level", testvalues.DefaultTrustLevel.String(), "--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod), "--base64"}, args...)
		proofHeight, ucAndMemProof, err := operator.MembershipProof(
			uint64(trustedHeight), operator.ToBase64KeyPaths(membershipKey), "",
			memArgs...,
		)
		s.Require().NoError(err)

		msg := sp1ics07tendermint.ILightClientMsgsMsgMembership{
			ProofHeight: *proofHeight,
			Proof:       ucAndMemProof,
			Path:        membershipKey,
			Value:       expValue,
		}

		tx, err := s.contract.Membership(s.GetTransactOpts(s.key), msg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		receipt := s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())
		s.T().Logf("Gas used in %s: %d", s.T().Name(), receipt.GasUsed)
	}))

	s.Require().True(s.Run("Verify non-membership", func() {
		var nonMembershipKey [][]byte
		s.Require().True(s.Run("Generate keys", func() {
			// A non-membership key:
			packetReceiptPath := ibchost.PacketReceiptKey(transfertypes.PortID, ibctesting.FirstChannelID, 1)

			nonMembershipKey = [][]byte{[]byte(ibcexported.StoreKey), packetReceiptPath}
		}))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		trustedHeight := clientState.LatestHeight.RevisionHeight

		nonMemArgs := append([]string{"--trust-level", testvalues.DefaultTrustLevel.String(), "--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod), "--base64"}, args...)
		proofHeight, ucAndMemProof, err := operator.MembershipProof(
			uint64(trustedHeight), operator.ToBase64KeyPaths(nonMembershipKey), "",
			nonMemArgs...,
		)
		s.Require().NoError(err)

		msg := sp1ics07tendermint.ILightClientMsgsMsgMembership{
			ProofHeight: *proofHeight,
			Proof:       ucAndMemProof,
			Path:        nonMembershipKey,
			Value:       []byte(""),
		}

		tx, err := s.contract.Membership(s.GetTransactOpts(s.key), msg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		receipt := s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())
		s.T().Logf("Gas used in %s: %d", s.T().Name(), receipt.GasUsed)
	}))
}

func (s *SP1ICS07TendermintTestSuite) TestUpdateClientAndMembership_Plonk() {
	ctx := context.Background()
	s.UpdateClientAndMembershipTest(ctx, "-p", "plonk")
}

func (s *SP1ICS07TendermintTestSuite) TestUpdateClientAndMembership_Groth16() {
	ctx := context.Background()
	s.UpdateClientAndMembershipTest(ctx, "-p", "groth16")
}

// UpdateClientAndMembershipTest tests the update client and membership functionality with the given arguments
func (s *SP1ICS07TendermintTestSuite) UpdateClientAndMembershipTest(ctx context.Context, opArgs ...string) {
	s.SetupSuite(ctx, opArgs...)

	eth, simd := s.ChainA, s.ChainB

	if s.generateFixtures {
		s.T().Log("Generate fixtures is set to true, but TestUpdateClientAndMembership does not support it (yet)")
	}

	s.Require().True(s.Run("Update and verify (non)membership", func() {
		var (
			membershipKey    [][]byte
			nonMembershipKey [][]byte
		)
		s.Require().True(s.Run("Generate keys", func() {
			// Prove the bank balance of UserA
			key, err := types.BankBalanceKey(s.UserB.Address(), simd.Config().Denom)
			s.Require().NoError(err)

			membershipKey = [][]byte{[]byte(banktypes.StoreKey), key}

			// A non-membership key:
			packetReceiptPath := ibchost.PacketReceiptKey(transfertypes.PortID, ibctesting.FirstChannelID, 1)

			nonMembershipKey = [][]byte{[]byte(ibcexported.StoreKey), packetReceiptPath}
		}))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		trustedHeight := clientState.LatestHeight.RevisionHeight

		latestHeight, err := simd.Height(ctx)
		s.Require().NoError(err)

		s.Require().Greater(uint32(latestHeight), trustedHeight)

		var expValue []byte
		s.Require().True(s.Run("Get expected value for the verify membership", func() {
			resp, err := e2esuite.ABCIQuery(ctx, simd, &abci.RequestQuery{
				Path:   "store/" + string(membershipKey[0]) + "/key",
				Data:   membershipKey[1],
				Height: latestHeight - 1,
			})
			s.Require().NoError(err)
			s.Require().NotEmpty(resp.Value)

			expValue = resp.Value
		}))

		proofHeight, ucAndMemProof, err := operator.UpdateClientAndMembershipProof(
			uint64(trustedHeight), uint64(latestHeight),
			operator.ToBase64KeyPaths(membershipKey, nonMembershipKey),
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
			"--base64",
		)
		s.Require().NoError(err)

		msg := sp1ics07tendermint.ILightClientMsgsMsgMembership{
			ProofHeight: *proofHeight,
			Proof:       ucAndMemProof,
			Path:        membershipKey,
			Value:       expValue,
		}

		tx, err := s.contract.Membership(s.GetTransactOpts(s.key), msg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		receipt := s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())
		s.T().Logf("Gas used in %s: %d", s.T().Name(), receipt.GasUsed)

		clientState, err = s.contract.GetClientState(nil)
		s.Require().NoError(err)

		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, trustedHeight)
		s.Require().Equal(proofHeight.RevisionHeight, clientState.LatestHeight.RevisionHeight)
		s.Require().False(clientState.IsFrozen)
	}))
}

func (s *SP1ICS07TendermintTestSuite) TestDoubleSignMisbehaviour_Plonk() {
	ctx := context.Background()
	s.DoubleSignMisbehaviourTest(ctx, "double_sign-plonk", "-p", "plonk")
}

func (s *SP1ICS07TendermintTestSuite) TestDoubleSignMisbehaviour_Groth16() {
	ctx := context.Background()
	s.DoubleSignMisbehaviourTest(ctx, "double_sign-groth16", "-p", "groth16")
}

// DoubleSignMisbehaviourTest tests the misbehaviour functionality with the given arguments
// Fixture is only generated if the environment variable is set
// Partially based on https://github.com/cosmos/relayer/blob/f9aaf3dd0ebfe99fbe98d190a145861d7df93804/interchaintest/misbehaviour_test.go#L38
func (s *SP1ICS07TendermintTestSuite) DoubleSignMisbehaviourTest(ctx context.Context, fixName string, opArgs ...string) {
	s.SetupSuite(ctx, opArgs...)

	eth, simd := s.ChainA, s.ChainB
	_ = eth

	var height clienttypes.Height
	var trustedHeader tmclient.Header
	s.Require().True(s.Run("Get trusted header", func() {
		var latestHeight int64
		var err error
		trustedHeader, latestHeight, err = ibcclientutils.QueryTendermintHeader(simd.Validators[0].CliContext())
		s.Require().NoError(err)
		s.Require().NotZero(latestHeight)

		height = clienttypes.NewHeight(clienttypes.ParseChainID(simd.Config().ChainID), uint64(latestHeight))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)
		trustedHeight := clienttypes.NewHeight(uint64(clientState.LatestHeight.RevisionNumber), uint64(clientState.LatestHeight.RevisionHeight))

		trustedHeader.TrustedHeight = trustedHeight
		trustedHeader.TrustedValidators = trustedHeader.ValidatorSet
	}))

	s.Require().True(s.Run("Invalid misbehaviour", func() {
		// Create a new valid header
		newHeader := s.CreateTMClientHeader(
			ctx,
			simd,
			int64(height.RevisionHeight+1),
			trustedHeader.GetTime().Add(time.Minute),
			trustedHeader,
		)

		invalidMisbehaviour := tmclient.Misbehaviour{
			Header1: &newHeader,
			Header2: &trustedHeader,
		}

		// The proof should fail because this is not misbehaviour (valid header for a new block)
		args := append([]string{
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
		},
			opArgs...,
		)
		_, err := operator.MisbehaviourProof(simd.GetCodec(), invalidMisbehaviour, "", args...)
		s.Require().ErrorContains(err, "Misbehaviour is not detected")
	}))

	s.Require().True(s.Run("Valid misbehaviour", func() {
		// create a duplicate header (with a different hash)
		newHeader := s.CreateTMClientHeader(
			ctx,
			simd,
			int64(height.RevisionHeight),
			trustedHeader.GetTime().Add(time.Minute),
			trustedHeader,
		)

		misbehaviour := tmclient.Misbehaviour{
			Header1: &newHeader,
			Header2: &trustedHeader,
		}

		var fixtureName string
		if s.generateFixtures {
			fixtureName = fixName
		}
		args := append([]string{
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
		},
			opArgs...,
		)
		submitMsg, err := operator.MisbehaviourProof(simd.GetCodec(), misbehaviour, fixtureName, args...)
		s.Require().NoError(err)

		tx, err := s.contract.Misbehaviour(s.GetTransactOpts(s.key), submitMsg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		receipt := s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())
		s.T().Logf("Gas used in %s: %d", s.T().Name(), receipt.GasUsed)

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)
		s.Require().True(clientState.IsFrozen)
	}))
}

func (s *SP1ICS07TendermintTestSuite) TestBreakingTimeMonotonicityMisbehaviour_Plonk() {
	ctx := context.Background()
	s.BreakingTimeMonotonicityMisbehaviourTest(ctx, "breaking_time_monotonicity-plonk", "-p", "plonk")
}

func (s *SP1ICS07TendermintTestSuite) TestBreakingTimeMonotonicityMisbehaviour_Groth16() {
	ctx := context.Background()
	s.BreakingTimeMonotonicityMisbehaviourTest(ctx, "breaking_time_monotonicity-groth16", "-p", "groth16")
}

// TestBreakingTimeMonotonicityMisbehaviour tests the misbehaviour functionality
// Fixture is only generated if the environment variable is set
// Partially based on https://github.com/cosmos/relayer/blob/f9aaf3dd0ebfe99fbe98d190a145861d7df93804/interchaintest/misbehaviour_test.go#L38
func (s *SP1ICS07TendermintTestSuite) BreakingTimeMonotonicityMisbehaviourTest(ctx context.Context, fixName string, opArgs ...string) {
	s.SetupSuite(ctx, opArgs...)

	eth, simd := s.ChainA, s.ChainB
	_ = eth

	var height clienttypes.Height
	var trustedHeader tmclient.Header
	s.Require().True(s.Run("Get trusted header", func() {
		var latestHeight int64
		var err error
		trustedHeader, latestHeight, err = ibcclientutils.QueryTendermintHeader(simd.Validators[0].CliContext())
		s.Require().NoError(err)
		s.Require().NotZero(latestHeight)

		height = clienttypes.NewHeight(clienttypes.ParseChainID(simd.Config().ChainID), uint64(latestHeight))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)
		trustedHeight := clienttypes.NewHeight(uint64(clientState.LatestHeight.RevisionNumber), uint64(clientState.LatestHeight.RevisionHeight))

		trustedHeader.TrustedHeight = trustedHeight
		trustedHeader.TrustedValidators = trustedHeader.ValidatorSet
	}))

	s.Require().True(s.Run("Valid misbehaviour", func() {
		// we have a trusted height n from trustedHeader
		// we now create two new headers n+1 and n+2 where both have time later than n
		// but n+2 has time earlier than n+1, which breaks time monotonicity

		// n+1
		header2 := s.CreateTMClientHeader(
			ctx,
			simd,
			int64(height.RevisionHeight+1),
			trustedHeader.GetTime().Add(time.Minute),
			trustedHeader,
		)

		// n+2 (with time earlier than n+1 and still after n)
		header1 := s.CreateTMClientHeader(
			ctx,
			simd,
			int64(height.RevisionHeight+2),
			trustedHeader.GetTime().Add(time.Minute).Add(-30*time.Second),
			trustedHeader,
		)

		misbehaviour := tmclient.Misbehaviour{
			Header1: &header1,
			Header2: &header2,
		}

		var fixtureName string
		if s.generateFixtures {
			fixtureName = fixName
		}
		args := append([]string{
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
		},
			opArgs...,
		)
		submitMsg, err := operator.MisbehaviourProof(simd.GetCodec(), misbehaviour, fixtureName, args...)
		s.Require().NoError(err)

		tx, err := s.contract.Misbehaviour(s.GetTransactOpts(s.key), submitMsg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		receipt := s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())
		s.T().Logf("Gas used in %s: %d", s.T().Name(), receipt.GasUsed)

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)
		s.Require().True(clientState.IsFrozen)
	}))
}
