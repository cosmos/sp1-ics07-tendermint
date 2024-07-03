// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package sp1ics07tendermint

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// ICS07TendermintClientState is an auto generated low-level Go binding around an user-defined struct.
type ICS07TendermintClientState struct {
	ChainId         string
	TrustLevel      ICS07TendermintTrustThreshold
	LatestHeight    ICS07TendermintHeight
	TrustingPeriod  uint64
	UnbondingPeriod uint64
	IsFrozen        bool
}

// ICS07TendermintConsensusState is an auto generated low-level Go binding around an user-defined struct.
type ICS07TendermintConsensusState struct {
	Timestamp          uint64
	Root               []byte
	NextValidatorsHash []byte
}

// ICS07TendermintHeight is an auto generated low-level Go binding around an user-defined struct.
type ICS07TendermintHeight struct {
	RevisionNumber uint32
	RevisionHeight uint32
}

// ICS07TendermintTrustThreshold is an auto generated low-level Go binding around an user-defined struct.
type ICS07TendermintTrustThreshold struct {
	Numerator   uint8
	Denominator uint8
}

// SP1ICS07TendermintEnv is an auto generated low-level Go binding around an user-defined struct.
type SP1ICS07TendermintEnv struct {
	ChainId        string
	TrustThreshold ICS07TendermintTrustThreshold
	TrustingPeriod uint64
	Now            uint64
}

// SP1ICS07TendermintSP1ICS07TendermintOutput is an auto generated low-level Go binding around an user-defined struct.
type SP1ICS07TendermintSP1ICS07TendermintOutput struct {
	TrustedConsensusState ICS07TendermintConsensusState
	NewConsensusState     ICS07TendermintConsensusState
	Env                   SP1ICS07TendermintEnv
	TrustedHeight         ICS07TendermintHeight
	NewHeight             ICS07TendermintHeight
}

// ContractMetaData contains all meta data concerning the Contract contract.
var ContractMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_ics07ProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"_verifier\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_clientState\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"_consensusState\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ALLOWED_SP1_CLOCK_DRIFT\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"clientState\",\"inputs\":[],\"outputs\":[{\"name\":\"chain_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trust_level\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"latest_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"trusting_period\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"unbonding_period\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"is_frozen\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"consensusStateHashes\",\"inputs\":[{\"name\":\"\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getClientState\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ClientState\",\"components\":[{\"name\":\"chain_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trust_level\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"latest_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"trusting_period\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"unbonding_period\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"is_frozen\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getConsensusState\",\"inputs\":[{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ics07UpdateClientProgramVkey\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validatePublicValues\",\"inputs\":[{\"name\":\"output\",\"type\":\"tuple\",\"internalType\":\"structSP1ICS07Tendermint.SP1ICS07TendermintOutput\",\"components\":[{\"name\":\"trusted_consensus_state\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"next_validators_hash\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"new_consensus_state\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"next_validators_hash\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"env\",\"type\":\"tuple\",\"internalType\":\"structSP1ICS07Tendermint.Env\",\"components\":[{\"name\":\"chain_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trust_threshold\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"trusting_period\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"now\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"trusted_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"new_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]}]}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifier\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISP1Verifier\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifyIcs07UpdateClientProof\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"}]",
}

// ContractABI is the input ABI used to generate the binding from.
// Deprecated: Use ContractMetaData.ABI instead.
var ContractABI = ContractMetaData.ABI

// Contract is an auto generated Go binding around an Ethereum contract.
type Contract struct {
	ContractCaller     // Read-only binding to the contract
	ContractTransactor // Write-only binding to the contract
	ContractFilterer   // Log filterer for contract events
}

// ContractCaller is an auto generated read-only Go binding around an Ethereum contract.
type ContractCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ContractTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ContractFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ContractSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ContractSession struct {
	Contract     *Contract         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ContractCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ContractCallerSession struct {
	Contract *ContractCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// ContractTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ContractTransactorSession struct {
	Contract     *ContractTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// ContractRaw is an auto generated low-level Go binding around an Ethereum contract.
type ContractRaw struct {
	Contract *Contract // Generic contract binding to access the raw methods on
}

// ContractCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ContractCallerRaw struct {
	Contract *ContractCaller // Generic read-only contract binding to access the raw methods on
}

// ContractTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ContractTransactorRaw struct {
	Contract *ContractTransactor // Generic write-only contract binding to access the raw methods on
}

// NewContract creates a new instance of Contract, bound to a specific deployed contract.
func NewContract(address common.Address, backend bind.ContractBackend) (*Contract, error) {
	contract, err := bindContract(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Contract{ContractCaller: ContractCaller{contract: contract}, ContractTransactor: ContractTransactor{contract: contract}, ContractFilterer: ContractFilterer{contract: contract}}, nil
}

// NewContractCaller creates a new read-only instance of Contract, bound to a specific deployed contract.
func NewContractCaller(address common.Address, caller bind.ContractCaller) (*ContractCaller, error) {
	contract, err := bindContract(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ContractCaller{contract: contract}, nil
}

// NewContractTransactor creates a new write-only instance of Contract, bound to a specific deployed contract.
func NewContractTransactor(address common.Address, transactor bind.ContractTransactor) (*ContractTransactor, error) {
	contract, err := bindContract(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ContractTransactor{contract: contract}, nil
}

// NewContractFilterer creates a new log filterer instance of Contract, bound to a specific deployed contract.
func NewContractFilterer(address common.Address, filterer bind.ContractFilterer) (*ContractFilterer, error) {
	contract, err := bindContract(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ContractFilterer{contract: contract}, nil
}

// bindContract binds a generic wrapper to an already deployed contract.
func bindContract(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ContractMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Contract *ContractRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Contract.Contract.ContractCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Contract *ContractRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Contract.Contract.ContractTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Contract *ContractRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Contract.Contract.ContractTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Contract *ContractCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Contract.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Contract *ContractTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Contract.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Contract *ContractTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Contract.Contract.contract.Transact(opts, method, params...)
}

// ALLOWEDSP1CLOCKDRIFT is a free data retrieval call binding the contract method 0x2c3ee474.
//
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint64)
func (_Contract *ContractCaller) ALLOWEDSP1CLOCKDRIFT(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "ALLOWED_SP1_CLOCK_DRIFT")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// ALLOWEDSP1CLOCKDRIFT is a free data retrieval call binding the contract method 0x2c3ee474.
//
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint64)
func (_Contract *ContractSession) ALLOWEDSP1CLOCKDRIFT() (uint64, error) {
	return _Contract.Contract.ALLOWEDSP1CLOCKDRIFT(&_Contract.CallOpts)
}

// ALLOWEDSP1CLOCKDRIFT is a free data retrieval call binding the contract method 0x2c3ee474.
//
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint64)
func (_Contract *ContractCallerSession) ALLOWEDSP1CLOCKDRIFT() (uint64, error) {
	return _Contract.Contract.ALLOWEDSP1CLOCKDRIFT(&_Contract.CallOpts)
}

// ClientState is a free data retrieval call binding the contract method 0xbd3ce6b0.
//
// Solidity: function clientState() view returns(string chain_id, (uint8,uint8) trust_level, (uint32,uint32) latest_height, uint64 trusting_period, uint64 unbonding_period, bool is_frozen)
func (_Contract *ContractCaller) ClientState(opts *bind.CallOpts) (struct {
	ChainId         string
	TrustLevel      ICS07TendermintTrustThreshold
	LatestHeight    ICS07TendermintHeight
	TrustingPeriod  uint64
	UnbondingPeriod uint64
	IsFrozen        bool
}, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "clientState")

	outstruct := new(struct {
		ChainId         string
		TrustLevel      ICS07TendermintTrustThreshold
		LatestHeight    ICS07TendermintHeight
		TrustingPeriod  uint64
		UnbondingPeriod uint64
		IsFrozen        bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ChainId = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.TrustLevel = *abi.ConvertType(out[1], new(ICS07TendermintTrustThreshold)).(*ICS07TendermintTrustThreshold)
	outstruct.LatestHeight = *abi.ConvertType(out[2], new(ICS07TendermintHeight)).(*ICS07TendermintHeight)
	outstruct.TrustingPeriod = *abi.ConvertType(out[3], new(uint64)).(*uint64)
	outstruct.UnbondingPeriod = *abi.ConvertType(out[4], new(uint64)).(*uint64)
	outstruct.IsFrozen = *abi.ConvertType(out[5], new(bool)).(*bool)

	return *outstruct, err

}

// ClientState is a free data retrieval call binding the contract method 0xbd3ce6b0.
//
// Solidity: function clientState() view returns(string chain_id, (uint8,uint8) trust_level, (uint32,uint32) latest_height, uint64 trusting_period, uint64 unbonding_period, bool is_frozen)
func (_Contract *ContractSession) ClientState() (struct {
	ChainId         string
	TrustLevel      ICS07TendermintTrustThreshold
	LatestHeight    ICS07TendermintHeight
	TrustingPeriod  uint64
	UnbondingPeriod uint64
	IsFrozen        bool
}, error) {
	return _Contract.Contract.ClientState(&_Contract.CallOpts)
}

// ClientState is a free data retrieval call binding the contract method 0xbd3ce6b0.
//
// Solidity: function clientState() view returns(string chain_id, (uint8,uint8) trust_level, (uint32,uint32) latest_height, uint64 trusting_period, uint64 unbonding_period, bool is_frozen)
func (_Contract *ContractCallerSession) ClientState() (struct {
	ChainId         string
	TrustLevel      ICS07TendermintTrustThreshold
	LatestHeight    ICS07TendermintHeight
	TrustingPeriod  uint64
	UnbondingPeriod uint64
	IsFrozen        bool
}, error) {
	return _Contract.Contract.ClientState(&_Contract.CallOpts)
}

// ConsensusStateHashes is a free data retrieval call binding the contract method 0x7733c36c.
//
// Solidity: function consensusStateHashes(uint32 ) view returns(bytes32)
func (_Contract *ContractCaller) ConsensusStateHashes(opts *bind.CallOpts, arg0 uint32) ([32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "consensusStateHashes", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ConsensusStateHashes is a free data retrieval call binding the contract method 0x7733c36c.
//
// Solidity: function consensusStateHashes(uint32 ) view returns(bytes32)
func (_Contract *ContractSession) ConsensusStateHashes(arg0 uint32) ([32]byte, error) {
	return _Contract.Contract.ConsensusStateHashes(&_Contract.CallOpts, arg0)
}

// ConsensusStateHashes is a free data retrieval call binding the contract method 0x7733c36c.
//
// Solidity: function consensusStateHashes(uint32 ) view returns(bytes32)
func (_Contract *ContractCallerSession) ConsensusStateHashes(arg0 uint32) ([32]byte, error) {
	return _Contract.Contract.ConsensusStateHashes(&_Contract.CallOpts, arg0)
}

// GetClientState is a free data retrieval call binding the contract method 0xef913a4b.
//
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint64,uint64,bool))
func (_Contract *ContractCaller) GetClientState(opts *bind.CallOpts) (ICS07TendermintClientState, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "getClientState")

	if err != nil {
		return *new(ICS07TendermintClientState), err
	}

	out0 := *abi.ConvertType(out[0], new(ICS07TendermintClientState)).(*ICS07TendermintClientState)

	return out0, err

}

// GetClientState is a free data retrieval call binding the contract method 0xef913a4b.
//
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint64,uint64,bool))
func (_Contract *ContractSession) GetClientState() (ICS07TendermintClientState, error) {
	return _Contract.Contract.GetClientState(&_Contract.CallOpts)
}

// GetClientState is a free data retrieval call binding the contract method 0xef913a4b.
//
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint64,uint64,bool))
func (_Contract *ContractCallerSession) GetClientState() (ICS07TendermintClientState, error) {
	return _Contract.Contract.GetClientState(&_Contract.CallOpts)
}

// GetConsensusState is a free data retrieval call binding the contract method 0xee3d9e5e.
//
// Solidity: function getConsensusState(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractCaller) GetConsensusState(opts *bind.CallOpts, revisionHeight uint32) ([32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "getConsensusState", revisionHeight)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetConsensusState is a free data retrieval call binding the contract method 0xee3d9e5e.
//
// Solidity: function getConsensusState(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractSession) GetConsensusState(revisionHeight uint32) ([32]byte, error) {
	return _Contract.Contract.GetConsensusState(&_Contract.CallOpts, revisionHeight)
}

// GetConsensusState is a free data retrieval call binding the contract method 0xee3d9e5e.
//
// Solidity: function getConsensusState(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractCallerSession) GetConsensusState(revisionHeight uint32) ([32]byte, error) {
	return _Contract.Contract.GetConsensusState(&_Contract.CallOpts, revisionHeight)
}

// Ics07UpdateClientProgramVkey is a free data retrieval call binding the contract method 0x975c0796.
//
// Solidity: function ics07UpdateClientProgramVkey() view returns(bytes32)
func (_Contract *ContractCaller) Ics07UpdateClientProgramVkey(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "ics07UpdateClientProgramVkey")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// Ics07UpdateClientProgramVkey is a free data retrieval call binding the contract method 0x975c0796.
//
// Solidity: function ics07UpdateClientProgramVkey() view returns(bytes32)
func (_Contract *ContractSession) Ics07UpdateClientProgramVkey() ([32]byte, error) {
	return _Contract.Contract.Ics07UpdateClientProgramVkey(&_Contract.CallOpts)
}

// Ics07UpdateClientProgramVkey is a free data retrieval call binding the contract method 0x975c0796.
//
// Solidity: function ics07UpdateClientProgramVkey() view returns(bytes32)
func (_Contract *ContractCallerSession) Ics07UpdateClientProgramVkey() ([32]byte, error) {
	return _Contract.Contract.Ics07UpdateClientProgramVkey(&_Contract.CallOpts)
}

// ValidatePublicValues is a free data retrieval call binding the contract method 0xccd65ced.
//
// Solidity: function validatePublicValues(((uint64,bytes,bytes),(uint64,bytes,bytes),(string,(uint8,uint8),uint64,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractCaller) ValidatePublicValues(opts *bind.CallOpts, output SP1ICS07TendermintSP1ICS07TendermintOutput) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "validatePublicValues", output)

	if err != nil {
		return err
	}

	return err

}

// ValidatePublicValues is a free data retrieval call binding the contract method 0xccd65ced.
//
// Solidity: function validatePublicValues(((uint64,bytes,bytes),(uint64,bytes,bytes),(string,(uint8,uint8),uint64,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractSession) ValidatePublicValues(output SP1ICS07TendermintSP1ICS07TendermintOutput) error {
	return _Contract.Contract.ValidatePublicValues(&_Contract.CallOpts, output)
}

// ValidatePublicValues is a free data retrieval call binding the contract method 0xccd65ced.
//
// Solidity: function validatePublicValues(((uint64,bytes,bytes),(uint64,bytes,bytes),(string,(uint8,uint8),uint64,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractCallerSession) ValidatePublicValues(output SP1ICS07TendermintSP1ICS07TendermintOutput) error {
	return _Contract.Contract.ValidatePublicValues(&_Contract.CallOpts, output)
}

// Verifier is a free data retrieval call binding the contract method 0x2b7ac3f3.
//
// Solidity: function verifier() view returns(address)
func (_Contract *ContractCaller) Verifier(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "verifier")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Verifier is a free data retrieval call binding the contract method 0x2b7ac3f3.
//
// Solidity: function verifier() view returns(address)
func (_Contract *ContractSession) Verifier() (common.Address, error) {
	return _Contract.Contract.Verifier(&_Contract.CallOpts)
}

// Verifier is a free data retrieval call binding the contract method 0x2b7ac3f3.
//
// Solidity: function verifier() view returns(address)
func (_Contract *ContractCallerSession) Verifier() (common.Address, error) {
	return _Contract.Contract.Verifier(&_Contract.CallOpts)
}

// VerifyIcs07UpdateClientProof is a paid mutator transaction binding the contract method 0x61d311c5.
//
// Solidity: function verifyIcs07UpdateClientProof(bytes proof, bytes publicValues) returns()
func (_Contract *ContractTransactor) VerifyIcs07UpdateClientProof(opts *bind.TransactOpts, proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "verifyIcs07UpdateClientProof", proof, publicValues)
}

// VerifyIcs07UpdateClientProof is a paid mutator transaction binding the contract method 0x61d311c5.
//
// Solidity: function verifyIcs07UpdateClientProof(bytes proof, bytes publicValues) returns()
func (_Contract *ContractSession) VerifyIcs07UpdateClientProof(proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.Contract.VerifyIcs07UpdateClientProof(&_Contract.TransactOpts, proof, publicValues)
}

// VerifyIcs07UpdateClientProof is a paid mutator transaction binding the contract method 0x61d311c5.
//
// Solidity: function verifyIcs07UpdateClientProof(bytes proof, bytes publicValues) returns()
func (_Contract *ContractTransactorSession) VerifyIcs07UpdateClientProof(proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.Contract.VerifyIcs07UpdateClientProof(&_Contract.TransactOpts, proof, publicValues)
}
