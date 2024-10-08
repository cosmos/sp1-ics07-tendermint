package testvalues

import (
	"time"

	ibctm "github.com/cosmos/ibc-go/v8/modules/light-clients/07-tendermint"

	"github.com/strangelove-ventures/interchaintest/v8/chain/ethereum"
)

const (
	// StartingTokenAmount is the amount of tokens to give to each user at the start of the test.
	StartingTokenAmount int64 = 10_000_000_000

	// Address of the SP1ICS07Tendermint contract.
	EnvKeyContractAddress = "CONTRACT_ADDRESS"
	// Tendermint RPC URL.
	EnvKeyTendermintRPC = "TENDERMINT_RPC_URL"
	// Ethereum RPC URL.
	EnvKeyEthRPC = "RPC_URL"
	// Private key used to submit transactions by the operator.
	EnvKeyPrivateKey = "PRIVATE_KEY"
	// The prover type (local|network|mock).
	EnvKeySp1Prover = "SP1_PROVER"
	// Private key for the prover network.
	EnvKeySp1PrivateKey = "SP1_PRIVATE_KEY"
	// EnvKeyGenerateFixtures Generate fixtures for the solidity tests if set to true.
	EnvKeyGenerateFixtures = "GENERATE_FIXTURES"
	// The log level for the Rust logger.
	EnvKeyRustLog = "RUST_LOG"

	// Log level for the Rust logger.
	EnvValueRustLog_Info = "info"
	// EnvValueGenerateFixtures_True is the value to set to generate fixtures for the solidity tests.
	EnvValueGenerateFixtures_True = "true"
)

var (
	// Maximum period to deposit on a proposal.
	// This value overrides the default value in the gov module using the `modifyGovV1AppState` function.
	MaxDepositPeriod = time.Second * 10
	// Duration of the voting period.
	// This value overrides the default value in the gov module using the `modifyGovV1AppState` function.
	VotingPeriod = time.Second * 30

	// StartingEthBalance is the amount of ETH to give to each user at the start of the test.
	StartingEthBalance = ethereum.ETHER.MulRaw(5)

	// DefaultTrustLevel is the trust level used by the SP1ICS07Tendermint contract.
	DefaultTrustLevel = ibctm.Fraction{Numerator: 2, Denominator: 3}.ToTendermint()

	// DefaultTrustPeriod is the trust period used by the SP1ICS07Tendermint contract.
	DefaultTrustPeriod = 1209669
)
