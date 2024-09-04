package e2esuite

import (
	"context"
	"crypto/ecdsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"regexp"
	"strconv"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	ethcommon "github.com/ethereum/go-ethereum/common"
	ethtypes "github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"

	"cosmossdk.io/math"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/tx"
	"github.com/cosmos/cosmos-sdk/crypto/keys/ed25519"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/cometbft/cometbft/crypto/tmhash"
	cometproto "github.com/cometbft/cometbft/proto/tendermint/types"
	comettypes "github.com/cometbft/cometbft/types"
	comettime "github.com/cometbft/cometbft/types/time"

	tmclient "github.com/cosmos/ibc-go/v8/modules/light-clients/07-tendermint"
	ibctesting "github.com/cosmos/ibc-go/v8/testing"
	ibcmocks "github.com/cosmos/ibc-go/v8/testing/mock"

	"github.com/strangelove-ventures/interchaintest/v8/chain/cosmos"
	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"
	"github.com/strangelove-ventures/interchaintest/v8/ibc"
	"github.com/strangelove-ventures/interchaintest/v8/testutil"
)

// FundAddressChainB sends funds to the given address on Chain B.
// The amount sent is 1,000,000,000 of the chain's denom.
func (s *TestSuite) FundAddressChainB(ctx context.Context, address string) {
	s.fundAddress(ctx, s.ChainB, s.UserB.KeyName(), address)
}

// BroadcastMessages broadcasts the provided messages to the given chain and signs them on behalf of the provided user.
// Once the broadcast response is returned, we wait for two blocks to be created on chain.
func (s *TestSuite) BroadcastMessages(ctx context.Context, chain *cosmos.CosmosChain, user ibc.Wallet, gas uint64, msgs ...sdk.Msg) (*sdk.TxResponse, error) {
	sdk.GetConfig().SetBech32PrefixForAccount(chain.Config().Bech32Prefix, chain.Config().Bech32Prefix+sdk.PrefixPublic)
	sdk.GetConfig().SetBech32PrefixForValidator(
		chain.Config().Bech32Prefix+sdk.PrefixValidator+sdk.PrefixOperator,
		chain.Config().Bech32Prefix+sdk.PrefixValidator+sdk.PrefixOperator+sdk.PrefixPublic,
	)

	broadcaster := cosmos.NewBroadcaster(s.T(), chain)

	broadcaster.ConfigureClientContextOptions(func(clientContext client.Context) client.Context {
		return clientContext.
			WithCodec(chain.Config().EncodingConfig.Codec).
			WithChainID(chain.Config().ChainID).
			WithTxConfig(chain.Config().EncodingConfig.TxConfig)
	})

	broadcaster.ConfigureFactoryOptions(func(factory tx.Factory) tx.Factory {
		return factory.WithGas(gas)
	})

	resp, err := cosmos.BroadcastTx(ctx, broadcaster, user, msgs...)
	if err != nil {
		return nil, err
	}

	// wait for 2 blocks for the transaction to be included
	s.Require().NoError(testutil.WaitForBlocks(ctx, 2, chain))

	return &resp, nil
}

// fundAddress sends funds to the given address on the given chain
func (s *TestSuite) fundAddress(ctx context.Context, chain *cosmos.CosmosChain, keyName, address string) {
	err := chain.SendFunds(ctx, keyName, ibc.WalletAmount{
		Address: address,
		Denom:   chain.Config().Denom,
		Amount:  math.NewInt(1_000_000_000),
	})
	s.Require().NoError(err)

	// wait for 2 blocks for the funds to be received
	err = testutil.WaitForBlocks(ctx, 2, chain)
	s.Require().NoError(err)
}

func (s *TestSuite) GetEthAddressFromStdout(stdout string) string {
	// Define the regular expression pattern
	re := regexp.MustCompile(`"value":"(0x[0-9a-fA-F]+)"`)

	// Find the first match
	matches := re.FindStringSubmatch(stdout)
	if len(matches) <= 1 {
		s.FailNow(fmt.Sprintf("no match found in stdout: %s", stdout))
	}
	// Extract the value
	return matches[1]
}

// GetEvmEvent parses the logs in the given receipt and returns the first event that can be parsed
func GetEvmEvent[T any](receipt *ethtypes.Receipt, parseFn func(log ethtypes.Log) (*T, error)) (event *T, err error) {
	for _, l := range receipt.Logs {
		event, err = parseFn(*l)
		if err == nil && event != nil {
			break
		}
	}

	if event == nil {
		err = fmt.Errorf("event not found")
	}

	return
}

// GetTransactOpts returns a new TransactOpts with the given private key
func (s *TestSuite) GetTransactOpts(key *ecdsa.PrivateKey) *bind.TransactOpts {
	chainIDStr, err := strconv.ParseInt(s.ChainA.Config().ChainID, 10, 64)
	s.Require().NoError(err)
	chainID := big.NewInt(chainIDStr)

	txOpts, err := bind.NewKeyedTransactorWithChainID(key, chainID)
	s.Require().NoError(err)

	return txOpts
}

func (s *TestSuite) GetTxReciept(ctx context.Context, chain *ethereum.EthereumChain, hash ethcommon.Hash) *ethtypes.Receipt {
	client, err := ethclient.Dial(chain.GetHostRPCAddress())
	s.Require().NoError(err)

	var receipt *ethtypes.Receipt
	err = testutil.WaitForCondition(time.Second*10, time.Second, func() (bool, error) {
		receipt, err = client.TransactionReceipt(ctx, hash)
		if err != nil {
			return false, nil
		}

		return receipt != nil, nil
	})

	// TODO: This should check if the tx was actually successful and return a bool or err on that basis

	s.Require().NoError(err)
	return receipt
}

// CreateTMClientHeader creates a new tendermint client header for the given chain, block height, and timestamp.
// It uses the given oldHeader as a base to create the new header with a new hash, and sign using the existing validators
// It can be used to for instance test misbehaviour
// Partially based on https://github.com/cosmos/relayer/blob/f9aaf3dd0ebfe99fbe98d190a145861d7df93804/interchaintest/misbehaviour_test.go#L38
func (s *TestSuite) CreateTMClientHeader(
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
	for i := range signers {
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
