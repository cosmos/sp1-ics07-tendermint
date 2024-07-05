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

You can build the programs for zkVM by running the following command:

```sh
just build-programs
```

## Run ICS-07 Tendermint Light Client End to End

1. Set the environment variables by filling in the `.env` file with the following:

    ```sh
    cp .env.example .env
    ```

    You need to fill in the `PRIVATE_KEY`, `SP1_PROVER`, `TENDERMINT_RPC_URL`, and `RPC_URL`. You also need the `SP1_PRIVATE_KEY` field if you are using the SP1 prover network.

2. Deploy the `SP1ICS07Tendermint` contract:

    ```sh
    just deploy-contracts
    ```

    This will generate the `contracts/script/genesis.json` file which contains the initialization parameters for the contract. And then deploy the contract using `contracts/script/SP1ICS07Tendermint.s.sol`.
    If you see the following error, add `--legacy` to the command in the `justfile`:
    ```text
    Error: Failed to get EIP-1559 fees    
    ```

3. Your deployed contract address will be printed to the terminal.

    ```text
    == Return ==
    0: address <CONTRACT_ADDRESS>
    ```

    This will be used when you run the operator in step 5. So add this to your `.env` file.

4. Run the Tendermint operator.

    ```sh
    just operator
    ```

## EVM-Compatible Proof Generation & Verification

> [!WARNING]
> You will need at least 128GB RAM to generate the PLONK proof.

Here, I will show you how to generate a proof to be used in the fixtures for the foundry tests. You can do this locally or by using the SP1 prover network. To do this on your local machine, run the following command:

```sh
RUST_BACKTRACE=full RUST_LOG=info SP1_PROVER="local" TENDERMINT_RPC_URL="https://rpc.celestia-mocha.com/" cargo run --bin fixture --release -- --trusted-block 2110658 --target-block 2110668
```

To use the SP1 prover network, you will need to set the `SP1_PROVER` environment variable to `network` and provide your private key to `.env`. After this, you can run the following command:

```sh
just network-fixtures
```

### Solidity Proof Verification

After generating the verify the proof with the SP1 EVM verifier.

```sh
just test-foundry
```

