package operator

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"os/exec"
	"strconv"
	"strings"

	abi "github.com/ethereum/go-ethereum/accounts/abi"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/types/sp1ics07tendermint"
)

// membershipFixture is a struct that contains the membership proof and proof height
type membershipFixture struct {
	// hex encoded height
	ProofHeight string `json:"proofHeight"`
	// hex encoded proof
	MembershipProof string `json:"membershipProof"`
}

// RunGenesis is a function that runs the genesis script to generate genesis.json
func RunGenesis(args ...string) error {
	args = append([]string{"genesis"}, args...)
	return exec.Command("target/release/operator", args...).Run()
}

// StartOperator is a function that runs the operator
func StartOperator(args ...string) error {
	args = append([]string{"start"}, args...)
	return exec.Command("target/release/operator", args...).Run()
}

// UpdateClientAndMembershipProof is a function that generates an update client and membership proof
func UpdateClientAndMembershipProof(trusted_height, target_height uint64, paths ...string) (*sp1ics07tendermint.IICS02ClientMsgsHeight, []byte, error) {
	args := append([]string{"fixtures", "update-client-and-membership", "--trusted-block", strconv.FormatUint(trusted_height, 10), "--target-block", strconv.FormatUint(target_height, 10), "--key-paths"}, paths...)

	stdout, err := exec.Command("target/release/operator", args...).Output()
	if err != nil {
		return nil, nil, err
	}

	// eliminate non-json characters
	jsonStartIdx := strings.Index(string(stdout), "{")
	if jsonStartIdx == -1 {
		panic("no json found in output")
	}
	stdout = stdout[jsonStartIdx:]

	var membership membershipFixture
	err = json.Unmarshal(stdout, &membership)
	if err != nil {
		return nil, nil, err
	}

	heightBz, err := hex.DecodeString(membership.ProofHeight)
	if err != nil {
		return nil, nil, err
	}

	heightType, err := abi.NewType("tuple", "IICS02ClientMsgsHeight", []abi.ArgumentMarshaling{
		{Name: "revisionNumber", Type: "uint32"},
		{Name: "revisionHeight", Type: "uint32"},
	})
	if err != nil {
		return nil, nil, err
	}

	heightArgs := abi.Arguments{
		{Type: heightType, Name: "param_one"},
	}

	// abi encoding
	heightI, err := heightArgs.Unpack(heightBz)
	if err != nil {
		return nil, nil, err
	}

	height := abi.ConvertType(heightI[0], new(sp1ics07tendermint.IICS02ClientMsgsHeight)).(*sp1ics07tendermint.IICS02ClientMsgsHeight)

	if height.RevisionHeight != uint32(target_height) {
		return nil, nil, errors.New("heights do not match")
	}

	proofBz, err := hex.DecodeString(membership.MembershipProof)
	if err != nil {
		return nil, nil, err
	}

	return height, proofBz, nil
}
