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

// MembershipProgramKVPair is an auto generated low-level Go binding around an user-defined struct.
type MembershipProgramKVPair struct {
	Key   string
	Value []byte
}

// MembershipProgramMembershipOutput is an auto generated low-level Go binding around an user-defined struct.
type MembershipProgramMembershipOutput struct {
	CommitmentRoot [32]byte
	KvPairs        []MembershipProgramKVPair
}

// MisbehaviourProgramMisbehaviourOutput is an auto generated low-level Go binding around an user-defined struct.
type MisbehaviourProgramMisbehaviourOutput struct {
	IsMisbehaviour bool
}

// UpdateClientAndMembershipProgramUcAndMembershipOutput is an auto generated low-level Go binding around an user-defined struct.
type UpdateClientAndMembershipProgramUcAndMembershipOutput struct {
	UpdateClientOutput UpdateClientProgramUpdateClientOutput
	KvPairs            []MembershipProgramKVPair
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
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"updateClientProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"membershipProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"updateClientAndMembershipProgramVkey\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"verifier\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_clientState\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"_consensusState\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ALLOWED_SP1_CLOCK_DRIFT\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint16\",\"internalType\":\"uint16\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"abiPublicTypes\",\"inputs\":[{\"name\":\"output\",\"type\":\"tuple\",\"internalType\":\"structMembershipProgram.MembershipOutput\",\"components\":[{\"name\":\"commitmentRoot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"kvPairs\",\"type\":\"tuple[]\",\"internalType\":\"structMembershipProgram.KVPair[]\",\"components\":[{\"name\":\"key\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"value\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"output2\",\"type\":\"tuple\",\"internalType\":\"structUpdateClientAndMembershipProgram.UcAndMembershipOutput\",\"components\":[{\"name\":\"updateClientOutput\",\"type\":\"tuple\",\"internalType\":\"structUpdateClientProgram.UpdateClientOutput\",\"components\":[{\"name\":\"trustedConsensusState\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"nextValidatorsHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"newConsensusState\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ConsensusState\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"root\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"nextValidatorsHash\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"env\",\"type\":\"tuple\",\"internalType\":\"structUpdateClientProgram.Env\",\"components\":[{\"name\":\"chainId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trustThreshold\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"trustingPeriod\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"now\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"trustedHeight\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revisionNumber\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"newHeight\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revisionNumber\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]}]},{\"name\":\"kvPairs\",\"type\":\"tuple[]\",\"internalType\":\"structMembershipProgram.KVPair[]\",\"components\":[{\"name\":\"key\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"value\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"output3\",\"type\":\"tuple\",\"internalType\":\"structMisbehaviourProgram.MisbehaviourOutput\",\"components\":[{\"name\":\"isMisbehaviour\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"outputs\":[],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"batchVerifyMembership\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"proofHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"trustedConsensusStateBz\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"kvPairHashes\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getClientState\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.ClientState\",\"components\":[{\"name\":\"chainId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"trustLevel\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.TrustThreshold\",\"components\":[{\"name\":\"numerator\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"denominator\",\"type\":\"uint8\",\"internalType\":\"uint8\"}]},{\"name\":\"latestHeight\",\"type\":\"tuple\",\"internalType\":\"structICS07Tendermint.Height\",\"components\":[{\"name\":\"revisionNumber\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}]},{\"name\":\"trustingPeriod\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"unbondingPeriod\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"isFrozen\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getConsensusStateHash\",\"inputs\":[{\"name\":\"revisionHeight\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVerifierInfo\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateClient\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumUpdateClientProgram.UpdateResult\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateClientAndBatchVerifyMembership\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"publicValues\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"kvPairHashes\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumUpdateClientProgram.UpdateResult\"}],\"stateMutability\":\"nonpayable\"}]",
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
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint16)
func (_Contract *ContractCaller) ALLOWEDSP1CLOCKDRIFT(opts *bind.CallOpts) (uint16, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "ALLOWED_SP1_CLOCK_DRIFT")

	if err != nil {
		return *new(uint16), err
	}

	out0 := *abi.ConvertType(out[0], new(uint16)).(*uint16)

	return out0, err

}

// ALLOWEDSP1CLOCKDRIFT is a free data retrieval call binding the contract method 0x2c3ee474.
//
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint16)
func (_Contract *ContractSession) ALLOWEDSP1CLOCKDRIFT() (uint16, error) {
	return _Contract.Contract.ALLOWEDSP1CLOCKDRIFT(&_Contract.CallOpts)
}

// ALLOWEDSP1CLOCKDRIFT is a free data retrieval call binding the contract method 0x2c3ee474.
//
// Solidity: function ALLOWED_SP1_CLOCK_DRIFT() view returns(uint16)
func (_Contract *ContractCallerSession) ALLOWEDSP1CLOCKDRIFT() (uint16, error) {
	return _Contract.Contract.ALLOWEDSP1CLOCKDRIFT(&_Contract.CallOpts)
}

// AbiPublicTypes is a free data retrieval call binding the contract method 0x887389cb.
//
// Solidity: function abiPublicTypes((bytes32,(string,bytes)[]) output, (((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)),(string,bytes)[]) output2, (bool) output3) pure returns()
func (_Contract *ContractCaller) AbiPublicTypes(opts *bind.CallOpts, output MembershipProgramMembershipOutput, output2 UpdateClientAndMembershipProgramUcAndMembershipOutput, output3 MisbehaviourProgramMisbehaviourOutput) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "abiPublicTypes", output, output2, output3)

	if err != nil {
		return err
	}

	return err

}

// AbiPublicTypes is a free data retrieval call binding the contract method 0x887389cb.
//
// Solidity: function abiPublicTypes((bytes32,(string,bytes)[]) output, (((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)),(string,bytes)[]) output2, (bool) output3) pure returns()
func (_Contract *ContractSession) AbiPublicTypes(output MembershipProgramMembershipOutput, output2 UpdateClientAndMembershipProgramUcAndMembershipOutput, output3 MisbehaviourProgramMisbehaviourOutput) error {
	return _Contract.Contract.AbiPublicTypes(&_Contract.CallOpts, output, output2, output3)
}

// AbiPublicTypes is a free data retrieval call binding the contract method 0x887389cb.
//
// Solidity: function abiPublicTypes((bytes32,(string,bytes)[]) output, (((uint64,bytes32,bytes32),(uint64,bytes32,bytes32),(string,(uint8,uint8),uint32,uint64),(uint32,uint32),(uint32,uint32)),(string,bytes)[]) output2, (bool) output3) pure returns()
func (_Contract *ContractCallerSession) AbiPublicTypes(output MembershipProgramMembershipOutput, output2 UpdateClientAndMembershipProgramUcAndMembershipOutput, output3 MisbehaviourProgramMisbehaviourOutput) error {
	return _Contract.Contract.AbiPublicTypes(&_Contract.CallOpts, output, output2, output3)
}

// BatchVerifyMembership is a free data retrieval call binding the contract method 0xa3b16959.
//
// Solidity: function batchVerifyMembership(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, bytes32[] kvPairHashes) view returns()
func (_Contract *ContractCaller) BatchVerifyMembership(opts *bind.CallOpts, proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, kvPairHashes [][32]byte) error {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "batchVerifyMembership", proof, publicValues, proofHeight, trustedConsensusStateBz, kvPairHashes)

	if err != nil {
		return err
	}

	return err

}

// BatchVerifyMembership is a free data retrieval call binding the contract method 0xa3b16959.
//
// Solidity: function batchVerifyMembership(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, bytes32[] kvPairHashes) view returns()
func (_Contract *ContractSession) BatchVerifyMembership(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, kvPairHashes [][32]byte) error {
	return _Contract.Contract.BatchVerifyMembership(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, kvPairHashes)
}

// BatchVerifyMembership is a free data retrieval call binding the contract method 0xa3b16959.
//
// Solidity: function batchVerifyMembership(bytes proof, bytes publicValues, uint32 proofHeight, bytes trustedConsensusStateBz, bytes32[] kvPairHashes) view returns()
func (_Contract *ContractCallerSession) BatchVerifyMembership(proof []byte, publicValues []byte, proofHeight uint32, trustedConsensusStateBz []byte, kvPairHashes [][32]byte) error {
	return _Contract.Contract.BatchVerifyMembership(&_Contract.CallOpts, proof, publicValues, proofHeight, trustedConsensusStateBz, kvPairHashes)
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

// GetConsensusStateHash is a free data retrieval call binding the contract method 0x0e954111.
//
// Solidity: function getConsensusStateHash(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractCaller) GetConsensusStateHash(opts *bind.CallOpts, revisionHeight uint32) ([32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "getConsensusStateHash", revisionHeight)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetConsensusStateHash is a free data retrieval call binding the contract method 0x0e954111.
//
// Solidity: function getConsensusStateHash(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractSession) GetConsensusStateHash(revisionHeight uint32) ([32]byte, error) {
	return _Contract.Contract.GetConsensusStateHash(&_Contract.CallOpts, revisionHeight)
}

// GetConsensusStateHash is a free data retrieval call binding the contract method 0x0e954111.
//
// Solidity: function getConsensusStateHash(uint32 revisionHeight) view returns(bytes32)
func (_Contract *ContractCallerSession) GetConsensusStateHash(revisionHeight uint32) ([32]byte, error) {
	return _Contract.Contract.GetConsensusStateHash(&_Contract.CallOpts, revisionHeight)
}

// GetVerifierInfo is a free data retrieval call binding the contract method 0xe215abff.
//
// Solidity: function getVerifierInfo() view returns(address, bytes32, bytes32, bytes32)
func (_Contract *ContractCaller) GetVerifierInfo(opts *bind.CallOpts) (common.Address, [32]byte, [32]byte, [32]byte, error) {
	var out []interface{}
	err := _Contract.contract.Call(opts, &out, "getVerifierInfo")

	if err != nil {
		return *new(common.Address), *new([32]byte), *new([32]byte), *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	out1 := *abi.ConvertType(out[1], new([32]byte)).(*[32]byte)
	out2 := *abi.ConvertType(out[2], new([32]byte)).(*[32]byte)
	out3 := *abi.ConvertType(out[3], new([32]byte)).(*[32]byte)

	return out0, out1, out2, out3, err

}

// GetVerifierInfo is a free data retrieval call binding the contract method 0xe215abff.
//
// Solidity: function getVerifierInfo() view returns(address, bytes32, bytes32, bytes32)
func (_Contract *ContractSession) GetVerifierInfo() (common.Address, [32]byte, [32]byte, [32]byte, error) {
	return _Contract.Contract.GetVerifierInfo(&_Contract.CallOpts)
}

// GetVerifierInfo is a free data retrieval call binding the contract method 0xe215abff.
//
// Solidity: function getVerifierInfo() view returns(address, bytes32, bytes32, bytes32)
func (_Contract *ContractCallerSession) GetVerifierInfo() (common.Address, [32]byte, [32]byte, [32]byte, error) {
	return _Contract.Contract.GetVerifierInfo(&_Contract.CallOpts)
}

// UpdateClient is a paid mutator transaction binding the contract method 0x195c0d3b.
//
// Solidity: function updateClient(bytes proof, bytes publicValues) returns(uint8)
func (_Contract *ContractTransactor) UpdateClient(opts *bind.TransactOpts, proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "updateClient", proof, publicValues)
}

// UpdateClient is a paid mutator transaction binding the contract method 0x195c0d3b.
//
// Solidity: function updateClient(bytes proof, bytes publicValues) returns(uint8)
func (_Contract *ContractSession) UpdateClient(proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.Contract.UpdateClient(&_Contract.TransactOpts, proof, publicValues)
}

// UpdateClient is a paid mutator transaction binding the contract method 0x195c0d3b.
//
// Solidity: function updateClient(bytes proof, bytes publicValues) returns(uint8)
func (_Contract *ContractTransactorSession) UpdateClient(proof []byte, publicValues []byte) (*types.Transaction, error) {
	return _Contract.Contract.UpdateClient(&_Contract.TransactOpts, proof, publicValues)
}

// UpdateClientAndBatchVerifyMembership is a paid mutator transaction binding the contract method 0xa51c335e.
//
// Solidity: function updateClientAndBatchVerifyMembership(bytes proof, bytes publicValues, bytes32[] kvPairHashes) returns(uint8)
func (_Contract *ContractTransactor) UpdateClientAndBatchVerifyMembership(opts *bind.TransactOpts, proof []byte, publicValues []byte, kvPairHashes [][32]byte) (*types.Transaction, error) {
	return _Contract.contract.Transact(opts, "updateClientAndBatchVerifyMembership", proof, publicValues, kvPairHashes)
}

// UpdateClientAndBatchVerifyMembership is a paid mutator transaction binding the contract method 0xa51c335e.
//
// Solidity: function updateClientAndBatchVerifyMembership(bytes proof, bytes publicValues, bytes32[] kvPairHashes) returns(uint8)
func (_Contract *ContractSession) UpdateClientAndBatchVerifyMembership(proof []byte, publicValues []byte, kvPairHashes [][32]byte) (*types.Transaction, error) {
	return _Contract.Contract.UpdateClientAndBatchVerifyMembership(&_Contract.TransactOpts, proof, publicValues, kvPairHashes)
}

// UpdateClientAndBatchVerifyMembership is a paid mutator transaction binding the contract method 0xa51c335e.
//
// Solidity: function updateClientAndBatchVerifyMembership(bytes proof, bytes publicValues, bytes32[] kvPairHashes) returns(uint8)
func (_Contract *ContractTransactorSession) UpdateClientAndBatchVerifyMembership(proof []byte, publicValues []byte, kvPairHashes [][32]byte) (*types.Transaction, error) {
	return _Contract.Contract.UpdateClientAndBatchVerifyMembership(&_Contract.TransactOpts, proof, publicValues, kvPairHashes)
}
