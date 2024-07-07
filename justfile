set dotenv-load

# Build riscv elf file using `cargo prove build` command
build-programs:
  cd programs/update-client && cargo prove build
  mv elf/riscv32im-succinct-zkvm-elf elf/update-client-riscv32im-succinct-zkvm-elf
  @echo "ELF created at 'elf/update-client-riscv32im-succinct-zkvm-elf'"
  cd programs/membership && cargo prove build
  mv elf/riscv32im-succinct-zkvm-elf elf/membership-riscv32im-succinct-zkvm-elf
  @echo "ELF created at 'elf/membership-riscv32im-succinct-zkvm-elf'"

# Build the operator executable using `cargo build` command
build-operator:
  cargo build --bin operator --locked --release
  @echo "Built the operator executable"

# Run the Solidity tests using `forge test` command
test-foundry:
  cd contracts && forge test -vvv

# Run the Rust tests using `cargo test` command (excluding the sp1-ics07-tendermint-update-client crate)
test-cargo:
  cargo test --workspace --exclude sp1-ics07-tendermint-update-client --exclude sp1-ics07-tendermint-membership --locked --all-features

# Generate the `genesis.json` file using $TENDERMINT_RPC_URL in the `.env` file
genesis:
  @echo "Generating the genesis file for the Celestia Mocha testnet"
  @echo "Building the program..."
  just build-programs
  @echo "Generating the genesis file..."
  RUST_LOG=info cargo run --bin operator --release -- genesis

# Generate the `fixture.json` file for the Celestia Mocha testnet using the prover parameter.
# The prover parameter should be one of: ["mock", "network", "local"]
# This generates the fixtures for all programs in parallel using GNU parallel.
# If prover is set to network, this command requires the `SP1_PRIVATE_KEY` environment variable to be set.
fixtures prover:
  @echo "Generating fixtures for the Celestia Mocha testnet"
  @echo "Building the program..."
  just build-programs
  @echo "Building the operator..."
  just build-operator
  @echo "Generating fixtures... This may take a while (up to 20 minutes)"
  parallel --progress --shebang --ungroup -j 3 ::: \
    "RUST_LOG=info SP1_PROVER={{prover}} TENDERMINT_RPC_URL='https://rpc.celestia-mocha.com/' ./target/release/operator fixtures update-client --trusted-block 2110658 --target-block 2110668 -o 'contracts/fixtures/{{ if prover == "mock" { "mock_" } else { "" } }}update_client_fixture.json'" \
    "{{ if prover == "network" { "sleep 15 &&" } else { "" } }} RUST_LOG=info SP1_PROVER={{prover}} TENDERMINT_RPC_URL='https://rpc.celestia-mocha.com/' ./target/release/operator fixtures membership --key-paths 'clients/07-tendermint-0/clientState' --trusted-block 2110658 -o 'contracts/fixtures/{{ if prover == "mock" { "mock_" } else { "" } }}verify_membership_fixture.json'" \
    "{{ if prover == "network" { "sleep 30 &&" } else { "" } }} RUST_LOG=info SP1_PROVER={{prover}} TENDERMINT_RPC_URL='https://rpc.celestia-mocha.com/' ./target/release/operator fixtures membership --key-paths clients/07-tendermint-0/clientState,clients/07-tendermint-001/clientState --trusted-block 2110658 -o 'contracts/fixtures/{{ if prover == "mock" { "mock_" } else { "" } }}verify_non_membership_fixture.json'"
  @echo "Fixtures generated at 'contracts/fixtures'"

# Generate the `SP1ICS07Tendermint.json` file containing the ABI of the SP1ICS07Tendermint contract
# Requires `jq` to be installed on the system
# Requires `abigen` to be installed on the system to generate the go bindings for e2e tests
generate-abi:
  cd contracts && forge install && forge build
  jq '.abi' contracts/out/SP1ICS07Tendermint.sol/SP1ICS07Tendermint.json > contracts/abi/SP1ICS07Tendermint.json
  @echo "ABI file created at 'contracts/abi/SP1ICS07Tendermint.json'"
  @echo "Generating go bindings for the end-to-end tests..."
  abigen --abi contracts/abi/SP1ICS07Tendermint.json --pkg sp1ics07tendermint --type Contract --out e2e/interchaintestv8/types/sp1ics07tendermint/contract.go
  @echo "Done."

# Deploy the SP1ICS07Tendermint contract to the Eth Sepolia testnet if the `.env` file is present
deploy-contracts:
  @echo "Deploying the SP1ICS07Tendermint contract"
  just genesis
  cd contracts && forge install
  @echo "Deploying the contract..."
  cd contracts && forge script script/SP1ICS07Tendermint.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Run the operator using the `cargo run --bin operator` command.
# This command requires the `.env` file to be present in the root directory.
operator:
  RUST_LOG=info cargo run --bin operator --release -- start

# Run the e2e tests
test-e2e testname:
  echo "Running {{testname}} test..."
  cd e2e/interchaintestv8 && go test -v -run=TestWithSP1ICS07TendermintTestSuite/{{testname}} -timeout 40m
