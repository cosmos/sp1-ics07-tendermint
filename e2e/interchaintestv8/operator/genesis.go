package operator

import "os/exec"

// RunGenesis is a function that runs the genesis script to generate genesis.json
func RunGenesis() error {
	return exec.Command("target/release/genesis").Run()
}
