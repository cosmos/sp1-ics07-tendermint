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
	TrustingPeriod  uint32
	UnbondingPeriod uint32
	IsFrozen        bool
}

// ICS07TendermintConsensusState is an auto generated low-level Go binding around an user-defined struct.
type ICS07TendermintConsensusState struct {
	Timestamp          uint64
	Root               [32]byte
	NextValidatorsHash [32]byte
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

// MembershipProgramMembershipOutput is an auto generated low-level Go binding around an user-defined struct.
type MembershipProgramMembershipOutput struct {
	CommitmentRoot [32]byte
	KeyPath        string
	Value          []byte
}

// UpdateClientProgramEnv is an auto generated low-level Go binding around an user-defined struct.
type UpdateClientProgramEnv struct {
	ChainId        string
	TrustThreshold ICS07TendermintTrustThreshold
	TrustingPeriod uint32
	Now            uint64
}

// UpdateClientProgramUpdateClientOutput is an auto generated low-level Go binding around an user-defined struct.
type UpdateClientProgramUpdateClientOutput struct {
	TrustedConsensusState ICS07TendermintConsensusState
	NewConsensusState     ICS07TendermintConsensusState
	Env                   UpdateClientProgramEnv
	TrustedHeight         ICS07TendermintHeight
	NewHeight             ICS07TendermintHeight
}

// ContractMetaData contains all meta data concerning the Contract contract.
var ContractMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_ics07UpdateClientProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"_ics07VerifyMembershipProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"_verifier\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_clientState\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"_consensusState\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ALLOWED_SP1_CLOCK_DRIFT\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getClientState\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ClientState\",\"components\":[{\"name\":\"chain_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trust_level\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"latest_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"trusting_period\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"unbonding_period\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"is_frozen\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getConsensusState\",\"inputs\":[{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ics07UpdateClientProgramVkey\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ics07VerifyMembershipProgramVkey\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateMembershipOutput\",\"inputs\":[{\"name\":\"output\",\"type\":\"tuple\",\"internalType\":\"structMembershipProgram.MembershipOutput\",\"components\":[{\"name\":\"commitment_root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"key_path\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"value\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"proofHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"trustedConsensusStateBz\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"keyPath\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"next_validators_hash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validateUpdateClientPublicValues\",\"inputs\":[{\"name\":\"output\",\"type\":\"tuple\",\"internalType\":\"structUpdateClientProgram.UpdateClientOutput\",\"components\":[{\"name\":\"trusted_consensus_state\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"next_validators_hash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"new_consensus_state\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"next_validators_hash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"env\",\"type\":\"tuple\",\"internalType\":\"structUpdateClientProgram.Env\",\"components\":[{\"name\":\"chain_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trust_threshold\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"trusting_period\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"now\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"trusted_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"new_height\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revision_height\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]}]}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifier\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISP1Verifier\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifyIcs07UpdateClientProof\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"verifyIcs07VerifyMembershipProof\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"proofHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"trustedConsensusStateBz\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"keyPath\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"value\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"verifyIcs07VerifyNonMembershipProof\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"proofHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"trustedConsensusStateBz\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"keyPath\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"view\"}]",
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

// GetClientState is a free data retrieval call binding the contract method 0xef913a4b.
//
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint32,uint32,bool))
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
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint32,uint32,bool))
func (_Contract *ContractSession) GetClientState() (ICS07TendermintClientState, error) {
	return _Contract.Contract.GetClientState(&_Contract.CallOpts)
}

// GetClientState is a free data retrieval call binding the contract method 0xef913a4b.
//
// Solidity: function getClientState() view returns((string,(uint8,uint8),(uint32,uint32),uint32,uint32,bool))
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

// Ics07VerifyMembershipProgramVkey is a free data retrieval call binding the contract method 0xc77eb6c2.
//
// Solidity: function ics07VerifyMembershipProgramVkey() view returns(bytes32)
func (_Contract *ContractCaller) Ics07VerifyMembershipProgramVkey(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "ics07VerifyMembershipProgramVkey")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// Ics07VerifyMembershipProgramVkey is a free data retrieval call binding the contract method 0xc77eb6c2.
//
// Solidity: function ics07VerifyMembershipProgramVkey() view returns(bytes32)
func (_Contract *ContractSession) Ics07VerifyMembershipProgramVkey() ([32]byte, error) {
	return _Contract.Contract.Ics07VerifyMembershipProgramVkey(&_Contract.CallOpts)
}

// Ics07VerifyMembershipProgramVkey is a free data retrieval call binding the contract method 0xc77eb6c2.
//
// Solidity: function ics07VerifyMembershipProgramVkey() view returns(bytes32)
func (_Contract *ContractCallerSession) Ics07VerifyMembershipProgramVkey() ([32]byte, error) {
	return _Contract.Contract.Ics07VerifyMembershipProgramVkey(&_Contract.CallOpts)
}

// ValidateMembershipOutput is a free data retrieval call binding the contract method 0x344f089d.
//
// Solidity: function validateMembershipOutput((bytes32,string,bytes) output, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns((uint64,bytes32,bytes32))
func (_Contract *ContractCaller) ValidateMembershipOutput(opts *bind.CallOpts, output MembershipProgramMembershipOutput, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) (ICS07TendermintConsensusState, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "validateMembershipOutput", output, proofHeight, trustedConsensusStateBz, keyPath)

	if err != nil {
		return *new(ICS07TendermintConsensusState), err
	}

	out0 := *abi.ConvertType(out[0], new(ICS07TendermintConsensusState)).(*ICS07TendermintConsensusState)

	return out0, err

}

// ValidateMembershipOutput is a free data retrieval call binding the contract method 0x344f089d.
//
// Solidity: function validateMembershipOutput((bytes32,string,bytes) output, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns((uint64,bytes32,bytes32))
func (_Contract *ContractSession) ValidateMembershipOutput(output MembershipProgramMembershipOutput, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) (ICS07TendermintConsensusState, error) {
	return _Contract.Contract.ValidateMembershipOutput(&_Contract.CallOpts, output, proofHeight, trustedConsensusStateBz, keyPath)
}

// ValidateMembershipOutput is a free data retrieval call binding the contract method 0x344f089d.
//
// Solidity: function validateMembershipOutput((bytes32,string,bytes) output, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns((uint64,bytes32,bytes32))
func (_Contract *ContractCallerSession) ValidateMembershipOutput(output MembershipProgramMembershipOutput, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) (ICS07TendermintConsensusState, error) {
	return _Contract.Contract.ValidateMembershipOutput(&_Contract.CallOpts, output, proofHeight, trustedConsensusStateBz, keyPath)
}

// ValidateUpdateClientPublicValues is a free data retrieval call binding the contract method 0x8de6ce1a.
//
// Solidity: function validateUpdateClientPublicValues(((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractCaller) ValidateUpdateClientPublicValues(opts *bind.CallOpts, output UpdateClientProgramUpdateClientOutput) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "validateUpdateClientPublicValues", output)

	if err != nil {
		return err
	}

	return err

}

// ValidateUpdateClientPublicValues is a free data retrieval call binding the contract method 0x8de6ce1a.
//
// Solidity: function validateUpdateClientPublicValues(((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractSession) ValidateUpdateClientPublicValues(output UpdateClientProgramUpdateClientOutput) error {
	return _Contract.Contract.ValidateUpdateClientPublicValues(&_Contract.CallOpts, output)
}

// ValidateUpdateClientPublicValues is a free data retrieval call binding the contract method 0x8de6ce1a.
//
// Solidity: function validateUpdateClientPublicValues(((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)) output) view returns()
func (_Contract *ContractCallerSession) ValidateUpdateClientPublicValues(output UpdateClientProgramUpdateClientOutput) error {
	return _Contract.Contract.ValidateUpdateClientPublicValues(&_Contract.CallOpts, output)
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

// VerifyIcs07VerifyMembershipProof is a free data retrieval call binding the contract method 0x89eaa22b.
//
// Solidity: function verifyIcs07VerifyMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath, bytes value) view returns()
func (_Contract *ContractCaller) VerifyIcs07VerifyMembershipProof(opts *bind.CallOpts, proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string, value []byte) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "verifyIcs07VerifyMembershipProof", proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath, value)

	if err != nil {
		return err
	}

	return err

}

// VerifyIcs07VerifyMembershipProof is a free data retrieval call binding the contract method 0x89eaa22b.
//
// Solidity: function verifyIcs07VerifyMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath, bytes value) view returns()
func (_Contract *ContractSession) VerifyIcs07VerifyMembershipProof(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string, value []byte) error {
	return _Contract.Contract.VerifyIcs07VerifyMembershipProof(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath, value)
}

// VerifyIcs07VerifyMembershipProof is a free data retrieval call binding the contract method 0x89eaa22b.
//
// Solidity: function verifyIcs07VerifyMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath, bytes value) view returns()
func (_Contract *ContractCallerSession) VerifyIcs07VerifyMembershipProof(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string, value []byte) error {
	return _Contract.Contract.VerifyIcs07VerifyMembershipProof(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath, value)
}

// VerifyIcs07VerifyNonMembershipProof is a free data retrieval call binding the contract method 0xec09cc74.
//
// Solidity: function verifyIcs07VerifyNonMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns()
func (_Contract *ContractCaller) VerifyIcs07VerifyNonMembershipProof(opts *bind.CallOpts, proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "verifyIcs07VerifyNonMembershipProof", proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath)

	if err != nil {
		return err
	}

	return err

}

// VerifyIcs07VerifyNonMembershipProof is a free data retrieval call binding the contract method 0xec09cc74.
//
// Solidity: function verifyIcs07VerifyNonMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns()
func (_Contract *ContractSession) VerifyIcs07VerifyNonMembershipProof(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) error {
	return _Contract.Contract.VerifyIcs07VerifyNonMembershipProof(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath)
}

// VerifyIcs07VerifyNonMembershipProof is a free data retrieval call binding the contract method 0xec09cc74.
//
// Solidity: function verifyIcs07VerifyNonMembershipProof(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, string keyPath) view returns()
func (_Contract *ContractCallerSession) VerifyIcs07VerifyNonMembershipProof(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, keyPath string) error {
	return _Contract.Contract.VerifyIcs07VerifyNonMembershipProof(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, keyPath)
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
