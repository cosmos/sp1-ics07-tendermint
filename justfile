# Build riscv elf file using `cargo prove build` command
build-program:
  cd programs/update-client && cargo prove build
  @echo "ELF created at 'program/elf/riscv32im-succinct-zkvm-elf'"

# Run the Solidity tests using `forge test` command
test-foundry:
  cd contracts && forge test -vvv

# Run the Rust tests using `cargo test` command (excluding the sp1-ics07-tendermint-update-client crate)
test-cargo:
  cargo test --workspace --exclude sp1-ics07-tendermint-update-client --locked --all-features

# Generate the `genesis.json` file for the Celestia Mocha testnet
mocha-genesis:
   RUST_LOG=info TENDERMINT_RPC_URL="https://rpc.celestia-mocha.com/" cargo run --bin genesis --release

# Generate the `mock_fixture.json` file for the Celestia Mocha testnet using the mock prover
mock-fixtures:
  RUST_BACKTRACE=full RUST_LOG=info SP1_PROVER="mock" TENDERMINT_RPC_URL="https://rpc.celestia-mocha.com/" cargo run --bin fixture --release -- --trusted-block 2110658 --target-block 2110668

# Generate the `SP1ICS07Tendermint.json` file containing the ABI of the SP1ICS07Tendermint contract
generate-abi:
  cd contracts && forge install && forge build
  cp contracts/out/SP1ICS07Tendermint.sol/SP1ICS07Tendermint.json contracts/abi/
  @echo "ABI file created at 'contracts/abi/SP1ICS07Tendermint.json'"
