package operator

import "os/exec"

// RunGenesis is a function that runs the genesis script to generate genesis.json
func RunGenesis(args ...string) error {
	return exec.Command("target/release/genesis", args...).Run()
}

// RunOperator is a function that runs the operator
func RunOperator(args ...string) error {
	return exec.Command("target/release/operator", args...).Run()
}
