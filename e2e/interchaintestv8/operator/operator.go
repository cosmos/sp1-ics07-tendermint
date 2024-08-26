package operator

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"

	abi "github.com/ethereum/go-ethereum/accounts/abi"

	"github.com/cosmos/cosmos-sdk/codec"

	tmclient "github.com/cosmos/ibc-go/v8/modules/light-clients/07-tendermint"

	"github.com/srdtrk/sp1-ics07-tendermint/e2e/v8/types/sp1ics07tendermint"
)

// membershipFixture is a struct that contains the membership proof and proof height
type membershipFixture struct {
	// hex encoded height
	ProofHeight string `json:"proofHeight"`
	// hex encoded proof
	MembershipProof string `json:"membershipProof"`
}

type GenesisFixture struct {
	TrustedClientState string `json:"trustedClientState"`
	TrustedConsensusState string `json:"trustedConsensusState"`
	UpdateClientVkey string `json:"updateClientVkey"`
	MembershipVkey string `json:"membershipVkey"`
	UcAndMembershipVkey string `json:"ucAndMembershipVkey"`
	MisbehaviourVKey string `json:"misbehaviourVKey"`
}

type MisbehaviourFixture struct {
	GenesisFixture
	SubmitMsg string `json:"submitMsg"`
}

// RunGenesis is a function that runs the genesis script to generate genesis.json
func RunGenesis(args ...string) error {
	args = append([]string{"genesis"}, args...)
	cmd := exec.Command("target/release/operator", args...)
	cmd.Stdout = os.Stdout
	return cmd.Run()
}

// StartOperator is a function that runs the operator
func StartOperator(args ...string) error {
	args = append([]string{"start"}, args...)
	cmd := exec.Command("target/release/operator", args...)
	cmd.Stdout = os.Stdout
	return cmd.Run()
}

// UpdateClientAndMembershipProof is a function that generates an update client and membership proof
func UpdateClientAndMembershipProof(trusted_height, target_height uint64, paths string, args ...string) (*sp1ics07tendermint.IICS02ClientMsgsHeight, []byte, error) {
	args = append([]string{"fixtures", "update-client-and-membership", "--trusted-block", strconv.FormatUint(trusted_height, 10), "--target-block", strconv.FormatUint(target_height, 10), "--key-paths", paths}, args...)

	stdout, err := exec.Command("target/release/operator", args...).Output()
	if err != nil {
		return nil, nil, err
	}

	// NOTE: writing stdout to os.Stdout after execution due to how `.Output()` works
	os.Stdout.Write(stdout)

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

func Misbehaviour(cdc codec.Codec, misbehaviour tmclient.Misbehaviour, writeFixture bool) error {
	misbehaviourFileName := "misbehaviour.json"
	args := []string{"fixtures", "misbehaviour", "--misbehaviour-path", misbehaviourFileName}

	misbehaviour.ClientId = "07-tendermint-0" // We just have to set it to something to make the unmarshalling to work :P
	bzIntermediary, err := cdc.MarshalJSON(&misbehaviour)
	if err != nil {
		return err
	}
	var jsonIntermediary map[string]interface{}
	if err := json.Unmarshal(bzIntermediary, &jsonIntermediary); err != nil {
		return err
	}
	headerHexPaths := []string{
		"validator_set.proposer.address",
		"trusted_validators.proposer.address",
		"signed_header.header.last_block_id.hash",
		"signed_header.header.last_block_id.part_set_header.hash",
		"signed_header.header.app_hash",
		"signed_header.header.consensus_hash",
		"signed_header.header.data_hash",
		"signed_header.header.evidence_hash",
		"signed_header.header.last_commit_hash",
		"signed_header.header.last_results_hash",
		"signed_header.header.next_validators_hash",
		"signed_header.header.proposer_address",
		"signed_header.header.validators_hash",
		"signed_header.commit.block_id.hash",
		"signed_header.commit.block_id.part_set_header.hash",
	}

	var hexPaths []string
	for _, path := range headerHexPaths {
		hexPaths = append(hexPaths, "header_1."+path)
		hexPaths = append(hexPaths, "header_2."+path)
	}

	for _, path := range hexPaths {
		pathParts := strings.Split(path, ".")
		tmpIntermediary := jsonIntermediary
		for i := 0; i < len(pathParts)-1; i++ {
			var ok bool
			tmpIntermediary, ok = tmpIntermediary[pathParts[i]].(map[string]interface{})
			if !ok {
				fmt.Printf("path not found: %s\n", path)
				continue
			}
		}
		base64str, ok := tmpIntermediary[pathParts[len(pathParts)-1]].(string)
		if !ok {
			return fmt.Errorf("path not found: %s", path)
		}
		bz, err := base64.StdEncoding.DecodeString(base64str)
		if err != nil {
			return err
		}
		tmpIntermediary[pathParts[len(pathParts)-1]] = hex.EncodeToString(bz)
	}

	validators1 := jsonIntermediary["header_1"].(map[string]interface{})["validator_set"].(map[string]interface{})["validators"].([]interface{})
	validators2 := jsonIntermediary["header_2"].(map[string]interface{})["validator_set"].(map[string]interface{})["validators"].([]interface{})
	validators3 := jsonIntermediary["header_1"].(map[string]interface{})["trusted_validators"].(map[string]interface{})["validators"].([]interface{})
	validators4 := jsonIntermediary["header_2"].(map[string]interface{})["trusted_validators"].(map[string]interface{})["validators"].([]interface{})
	validators := validators1
	validators = append(validators, validators2...)
	validators = append(validators, validators3...)
	validators = append(validators, validators4...)
	for _, val := range validators {
		val := val.(map[string]interface{})
		valAddressBase64Str, ok := val["address"].(string)
		if !ok {
			return fmt.Errorf("address not found in path: %s", val)
		}
		valAddressBz, err := base64.StdEncoding.DecodeString(valAddressBase64Str)
		if err != nil {
			return err
		}
		val["address"] = hex.EncodeToString(valAddressBz)

		pubKey, ok := val["pub_key"].(map[string]interface{})
		if !ok {
			return fmt.Errorf("pub_key not found in path: %s", val)
		}
		ed25519PubKey := pubKey["ed25519"].(string)
		pubKey["type"] = "tendermint/PubKeyEd25519"
		pubKey["value"] = ed25519PubKey
	}

	var pubKeys []map[string]interface{}
	pubKeys = append(pubKeys, jsonIntermediary["header_1"].(map[string]interface{})["validator_set"].(map[string]interface{})["proposer"].(map[string]interface{})["pub_key"].(map[string]interface{}))
	pubKeys = append(pubKeys, jsonIntermediary["header_1"].(map[string]interface{})["trusted_validators"].(map[string]interface{})["proposer"].(map[string]interface{})["pub_key"].(map[string]interface{}))
	pubKeys = append(pubKeys, jsonIntermediary["header_2"].(map[string]interface{})["validator_set"].(map[string]interface{})["proposer"].(map[string]interface{})["pub_key"].(map[string]interface{}))
	pubKeys = append(pubKeys, jsonIntermediary["header_2"].(map[string]interface{})["trusted_validators"].(map[string]interface{})["proposer"].(map[string]interface{})["pub_key"].(map[string]interface{}))

	for _, proposerPubKey := range pubKeys {
		ed25519PubKey := proposerPubKey["ed25519"].(string)
		proposerPubKey["type"] = "tendermint/PubKeyEd25519"
		proposerPubKey["value"] = ed25519PubKey
	}

	header1Sigs := jsonIntermediary["header_1"].(map[string]interface{})["signed_header"].(map[string]interface{})["commit"].(map[string]interface{})["signatures"].([]interface{})
	header2Sigs := jsonIntermediary["header_2"].(map[string]interface{})["signed_header"].(map[string]interface{})["commit"].(map[string]interface{})["signatures"].([]interface{})
	sigs := header1Sigs
	sigs = append(sigs, header2Sigs...)
	for _, sig := range sigs {
		sig := sig.(map[string]interface{})
		if sig["block_id_flag"] == "BLOCK_ID_FLAG_COMMIT" {
			sig["block_id_flag"] = 2
		} else {
			return fmt.Errorf("unexpected block_id_flag: %s", sig["block_id_flag"])
		}

		valAddressBase64Str, ok := sig["validator_address"].(string)
		if !ok {
			return fmt.Errorf("validator_address not found")
		}
		valAddressBz, err := base64.StdEncoding.DecodeString(valAddressBase64Str)
		if err != nil {
			return err
		}
		sig["validator_address"] = hex.EncodeToString(valAddressBz)
	}

	misbehaviourBz, err := json.Marshal(jsonIntermediary)
	if err != nil {
		return err
	}

	// TODO: Make file temporary and delete it after use
	if err := os.WriteFile(misbehaviourFileName, misbehaviourBz, 0o600); err != nil {
		return err
	}

	stdout, err := exec.Command("target/release/operator", args...).Output()
	if err != nil {
		return err
	}

	// NOTE: writing stdout to os.Stdout after execution due to how `.Output()` works
	os.Stdout.Write(stdout)

	// eliminate non-json characters
	jsonStartIdx := strings.Index(string(stdout), "{")
	if jsonStartIdx == -1 {
		panic("no json found in output")
	}
	stdout = stdout[jsonStartIdx:]

	var misbehaviourFixture MisbehaviourFixture
	err = json.Unmarshal(stdout, &misbehaviour)
	if err != nil {
		return err
	}
	fmt.Println(misbehaviourFixture)

	if writeFixture {
		if err := os.WriteFile("contracts/fixtures/e2e_misbehaviour_fixture.json", stdout, 0o600); err != nil {
			return err
		}
	}

	return nil
}
