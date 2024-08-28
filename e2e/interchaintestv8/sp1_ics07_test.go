package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/suite"

	ethcommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/cosmos/cosmos-sdk/crypto/keys/ed25519"

	"github.com/cometbft/cometbft/crypto/tmhash"
	cometproto "github.com/cometbft/cometbft/proto/tendermint/types"
	comettypes "github.com/cometbft/cometbft/types"
	comettime "github.com/cometbft/cometbft/types/time"
	transfertypes "github.com/cosmos/ibc-go/v8/modules/apps/transfer/types"
	ibcclientutils "github.com/cosmos/ibc-go/v8/modules/core/02-client/client/utils"
	clienttypes "github.com/cosmos/ibc-go/v8/modules/core/02-client/types"
	ibchost "github.com/cosmos/ibc-go/v8/modules/core/24-host"
	ibcexported "github.com/cosmos/ibc-go/v8/modules/core/exported"
	tmclient "github.com/cosmos/ibc-go/v8/modules/light-clients/07-tendermint"
	ibctesting "github.com/cosmos/ibc-go/v8/testing"
	ibcmocks "github.com/cosmos/ibc-go/v8/testing/mock"

	"github.com/strangelove-ventures/interchaintest/v8/chain/cosmos"
	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum/foundry"
	"github.com/strangelove-ventures/interchaintest/v8/ibc"
	"github.com/strangelove-ventures/interchaintest/v8/testutil"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/e2esuite"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/operator"
	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/testvalues"
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

		os.Setenv(testvalues.EnvKeyRustLog, testvalues.EnvValueRustLog_Info)
		os.Setenv(testvalues.EnvKeyEthRPC, eth.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeyTendermintRPC, simd.GetHostRPCAddress())
		os.Setenv(testvalues.EnvKeySp1Prover, "network")
		os.Setenv(testvalues.EnvKeyPrivateKey, hexPrivateKey)
		if os.Getenv(testvalues.EnvKeyGenerateFixtures) == testvalues.EnvValueGenerateFixtures_True {
			s.generateFixtures = true
		}
		// make sure that the SP1_PRIVATE_KEY is set.
		s.Require().NotEmpty(os.Getenv(testvalues.EnvKeySp1PrivateKey))

		s.Require().NoError(eth.SendFunds(ctx, "faucet", ibc.WalletAmount{
			Amount:  testvalues.StartingEthBalance,
			Address: address,
		}))
	}))

	s.Require().True(s.Run("Deploy contracts", func() {
		s.Require().NoError(operator.RunGenesis(
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
			"-o", "contracts/script/genesis.json",
		))

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

// TestDeploy tests the deployment of the SP1ICS07Tendermint contract
func (s *SP1ICS07TendermintTestSuite) TestDeploy() {
	ctx := context.Background()

	s.SetupSuite(ctx)

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

// TestUpdateClient tests the update client functionality
func (s *SP1ICS07TendermintTestSuite) TestUpdateClient() {
	ctx := context.Background()

	s.SetupSuite(ctx)

	_, simd := s.ChainA, s.ChainB

	if s.generateFixtures {
		s.T().Log("Generate fixtures is set to true, but TestUpdateClient does not support it (yet)")
	}

	s.Require().True(s.Run("Update client", func() {
		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		initialHeight := clientState.LatestHeight.RevisionHeight

		s.Require().NoError(operator.StartOperator("--only-once"))

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

func (s *SP1ICS07TendermintTestSuite) TestUpdateClientAndMembership() {
	ctx := context.Background()

	s.SetupSuite(ctx)

	eth, simd := s.ChainA, s.ChainB

	if s.generateFixtures {
		s.T().Log("Generate fixtures is set to true, but TestUpdateClient does not support it (yet)")
	}

	s.Require().True(s.Run("Update and verify non-membership", func() {
		s.Require().NoError(testutil.WaitForBlocks(ctx, 5, simd))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)

		trustedHeight := clientState.LatestHeight.RevisionHeight

		latestHeight, err := simd.Height(ctx)
		s.Require().NoError(err)

		s.Require().Greater(uint32(latestHeight), trustedHeight)

		// This will be a non-membership proof since no packets have been sent
		packetReceiptPath := ibchost.PacketReceiptPath(transfertypes.PortID, ibctesting.FirstChannelID, 1)
		proofHeight, ucAndMemProof, err := operator.UpdateClientAndMembershipProof(
			uint64(trustedHeight), uint64(latestHeight), packetReceiptPath,
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod),
		)
		s.Require().NoError(err)

		msg := sp1ics07tendermint.ILightClientMsgsMsgMembership{
			ProofHeight: *proofHeight,
			Proof:       ucAndMemProof,
			Path:        [][]byte{[]byte(ibcexported.StoreKey), []byte(packetReceiptPath)},
			Value:       []byte(""),
		}

		tx, err := s.contract.Membership(s.GetTransactOpts(s.key), msg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		_ = s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())

		clientState, err = s.contract.GetClientState(nil)
		s.Require().NoError(err)

		s.Require().Equal(uint32(1), clientState.LatestHeight.RevisionNumber)
		s.Require().Greater(clientState.LatestHeight.RevisionHeight, trustedHeight)
		s.Require().Equal(proofHeight.RevisionHeight, clientState.LatestHeight.RevisionHeight)
		s.Require().False(clientState.IsFrozen)
	}))
}

func (s *SP1ICS07TendermintTestSuite) TestMisbehaviour() {
	ctx := context.Background()

	s.SetupSuite(ctx)

	eth, simd := s.ChainA, s.ChainB
	_ = eth

	s.Require().True(s.Run("Misbehave", func() {
		// Based off of: https://github.com/cosmos/relayer/blob/f9aaf3dd0ebfe99fbe98d190a145861d7df93804/interchaintest/misbehaviour_test.go#L38
		oldHeader, latestHeight, err := ibcclientutils.QueryTendermintHeader(simd.Validators[0].CliContext())
		s.Require().NoError(err)
		s.Require().NotZero(latestHeight)

		height := clienttypes.NewHeight(clienttypes.ParseChainID(simd.Config().ChainID), uint64(latestHeight))

		clientState, err := s.contract.GetClientState(nil)
		s.Require().NoError(err)
		trustedHeight := clienttypes.NewHeight(uint64(clientState.LatestHeight.RevisionNumber), uint64(clientState.LatestHeight.RevisionHeight))

		oldHeader.TrustedHeight = trustedHeight
		oldHeader.TrustedValidators = oldHeader.ValidatorSet // ?
		s.Require().NoError(err)

		// create a duplicate header (with a different hash)
		newHeader := s.createTMClientHeader(
			ctx,
			simd,
			int64(height.RevisionHeight),
			oldHeader.GetTime().Add(time.Minute),
			oldHeader,
		)
		_ = newHeader

		misbehaviour := tmclient.Misbehaviour{
			Header1: &newHeader,
			Header2: &oldHeader,
		}

		submitMsg, err := operator.Misbehaviour(simd.GetCodec(), misbehaviour, s.generateFixtures,
			"--trust-level", testvalues.DefaultTrustLevel.String(),
			"--trusting-period", strconv.Itoa(testvalues.DefaultTrustPeriod))
		s.Require().NoError(err)

		tx, err := s.contract.Misbehaviour(s.GetTransactOpts(s.key), submitMsg)
		s.Require().NoError(err)

		// wait until transaction is included in a block
		_ = s.GetTxReciept(ctx, eth.EthereumChain, tx.Hash())

		clientState, err = s.contract.GetClientState(nil)
		s.Require().NoError(err)
		s.Require().True(clientState.IsFrozen)
	}))
}

func (s *SP1ICS07TendermintTestSuite) createTMClientHeader(
	ctx context.Context,
	chain *cosmos.CosmosChain,
	blockHeight int64,
	timestamp time.Time,
	oldHeader tmclient.Header,
) tmclient.Header {
	var privVals []comettypes.PrivValidator
	var validators []*comettypes.Validator
	for _, chainVal := range chain.Validators {
		keyBz, err := chainVal.ReadFile(ctx, "config/priv_validator_key.json")
		s.Require().NoError(err)
		var privValidatorKeyFile cosmos.PrivValidatorKeyFile
		err = json.Unmarshal(keyBz, &privValidatorKeyFile)
		s.Require().NoError(err)
		decodedKeyBz, err := base64.StdEncoding.DecodeString(privValidatorKeyFile.PrivKey.Value)
		s.Require().NoError(err)

		privKey := &ed25519.PrivKey{
			Key: decodedKeyBz,
		}

		privVal := ibcmocks.PV{PrivKey: privKey}
		privVals = append(privVals, privVal)

		pubKey, err := privVal.GetPubKey()
		s.Require().NoError(err)

		val := comettypes.NewValidator(pubKey, oldHeader.ValidatorSet.Proposer.VotingPower)
		validators = append(validators, val)

	}

	valSet := comettypes.NewValidatorSet(validators)
	vsetHash := valSet.Hash()

	// Make sure all the signers are in the correct order as expected by the validator set
	signers := make([]comettypes.PrivValidator, valSet.Size())
	for i, _ := range signers {
		_, val := valSet.GetByIndex(int32(i))

		for _, pv := range privVals {
			pk, err := pv.GetPubKey()
			s.Require().NoError(err)

			if pk.Equals(val.PubKey) {
				signers[i] = pv
				break
			}
		}

		if signers[i] == nil {
			s.Require().FailNow("could not find signer for validator")
		}
	}

	tmHeader := comettypes.Header{
		Version:            oldHeader.Header.Version,
		ChainID:            oldHeader.Header.ChainID,
		Height:             blockHeight,
		Time:               timestamp,
		LastBlockID:        ibctesting.MakeBlockID(make([]byte, tmhash.Size), 10_000, make([]byte, tmhash.Size)),
		LastCommitHash:     oldHeader.Header.LastCommitHash,
		DataHash:           tmhash.Sum([]byte("data_hash")),
		ValidatorsHash:     vsetHash,
		NextValidatorsHash: vsetHash,
		ConsensusHash:      tmhash.Sum([]byte("consensus_hash")),
		AppHash:            tmhash.Sum([]byte("app_hash")),
		LastResultsHash:    tmhash.Sum([]byte("last_results_hash")),
		EvidenceHash:       tmhash.Sum([]byte("evidence_hash")),
		ProposerAddress:    valSet.Proposer.Address,
	}

	hhash := tmHeader.Hash()
	blockID := ibctesting.MakeBlockID(hhash, oldHeader.Commit.BlockID.PartSetHeader.Total, tmhash.Sum([]byte("part_set")))
	voteSet := comettypes.NewVoteSet(oldHeader.Header.ChainID, blockHeight, 1, cometproto.PrecommitType, valSet)

	voteProto := &comettypes.Vote{
		ValidatorAddress: nil,
		ValidatorIndex:   -1,
		Height:           blockHeight,
		Round:            1,
		Timestamp:        comettime.Now(),
		Type:             cometproto.PrecommitType,
		BlockID:          blockID,
	}

	for i, sign := range signers {
		pv, err := sign.GetPubKey()
		s.Require().NoError(err)
		addr := pv.Address()
		vote := voteProto.Copy()
		vote.ValidatorAddress = addr
		vote.ValidatorIndex = int32(i)
		_, err = comettypes.SignAndCheckVote(vote, sign, oldHeader.Header.ChainID, false)
		s.Require().NoError(err)
		added, err := voteSet.AddVote(vote)
		s.Require().NoError(err)
		s.Require().True(added)
	}
	extCommit := voteSet.MakeExtendedCommit(comettypes.DefaultABCIParams())
	commit := extCommit.ToCommit()

	signedHeader := &cometproto.SignedHeader{
		Header: tmHeader.ToProto(),
		Commit: commit.ToProto(),
	}

	valSetProto, err := valSet.ToProto()
	s.Require().NoError(err)

	return tmclient.Header{
		SignedHeader:      signedHeader,
		ValidatorSet:      valSetProto,
		TrustedHeight:     oldHeader.TrustedHeight,
		TrustedValidators: oldHeader.TrustedValidators,
	}
}
