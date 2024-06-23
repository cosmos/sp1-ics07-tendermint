# SP1 ICS07-Tendermint IBC Light Client

This is a WIP example of an [ICS-07](https://github.com/cosmos/ibc/tree/main/spec/client/ics-007-tendermint-client) IBC light client on Ethereum for powered by [SP1](https://github.com/succinctlabs/sp1) and [`ibc-rs`](https://github.com/cosmos/ibc-rs).

## Overview

This, `sp1-ics07-tendermint`, is an example of a ZK IBC tendermint light client on Ethereum. It's goal is to demonstrate how to use SP1 to generate proofs for:
- Updating the light client state (including historical headers) - implemented
- Misbehaviour detection (freezing the light client) - not implemented yet
- Verify membership proofs (for IBC packets) - not implemented yet
- Verify non-membership proofs (for IBC packets) - not implemented yet

This project is structured as a cargo workspace with the following directories:
* The `contracts` directory contains a Solidity contract that implements the ICS-07 Tendermint light client which can verify SP1 proofs. This is a [`foundry`](https://github.com/foundry-rs/foundry) project, and not a part of the cargo workspace.
* The `operator` directory contains a Rust program that interacts with the Solidity contract. It fetches the latest header (although it could also fetch historical headers) and generates a proof of the update using `ibc-rs`, and then updates the contract with the proof. It also contains several scripts to generate fixtures and proofs for testing.
* The `programs` directory contains the SP1 programs that are compiled to RiscV and run on the SP1's zkVM.
* The `packages` directory contains a shared rust library that is used by the `operator` and `programs` directories.

## Requirements

- [Rust](https://rustup.rs/)
- [SP1](https://succinctlabs.github.io/sp1/getting-started/install.html)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Just](https://just.systems/man/en/) (recommended)

## Build the programs

You can build the program for zkVM by running the following command:

```sh
just build-program
```

## Run ICS-07 Tendermint Light Client End to End

1. Generate the initialization parameters for the contract.

    ```sh
    cd operator
    TENDERMINT_RPC_URL=https://rpc.celestia-mocha.com/ cargo run --bin genesis --release
    ```

    This will show the tendermint vkey hash, trusted header hash, and trusted height, which you will
    need to initialize the SP1 Tendermint contract.

2. Deploy the `SP1Tendermint` contract with the initialization parameters:

    ```sh
    cd ../contracts

    forge install

    TENDERMINT_VKEY_HASH=<tendermint_vkey_hash> TRUSTED_HEADER_HASH=<trusted_header_hash> TRUSTED_HEIGHT=<trusted_height> forge script script/SP1Tendermint.s.sol --rpc-url https://ethereum-sepolia.publicnode.com/ --private-key <PRIVATE_KEY> --broadcast
    ```

    If you see the following error, add `--legacy` to the command.
    ```shell
    Error: Failed to get EIP-1559 fees    
    ```

## EVM-Compatible Proof Generation & Verification

> [!WARNING]
> You will need at least 128GB RAM to generate the PLONK proof.

Here, I will show you how to generate a proof to be used in the fixtures for the foundry tests. You can do this locally or by using the SP1 prover network. To do this on your local machine, run the following command:

```sh
RUST_BACKTRACE=full RUST_LOG=info SP1_PROVER="local" TENDERMINT_RPC_URL="https://rpc.celestia-mocha.com/" cargo run --bin fixture --release -- --trusted-block 2110658 --target-block 2110668
```

To use the SP1 prover network, you will need to set the `SP1_PROVER` environment variable to `network` and provide your private key. You can do this by running the following command:

```sh
RUST_BACKTRACE=full RUST_LOG=info SP1_PROVER="network" SP1_PRIVATE_KEY="YOUR_PRIVATE_KEY" TENDERMINT_RPC_URL="https://rpc.celestia-mocha.com/" cargo run --bin fixture --release -- --trusted-block 2110658 --target-block 2110668
```

### Solidity Proof Verification

After generating the verify the proof with the SP1 EVM verifier.

```sh
just test-foundry
```

