# SP1 ICS07-Tendermint IBC Light Client

<div align="center">

[![Github Actions][gha-badge]][gha]
[![SP1][sp1-badge]][sp1]
[![License: MIT][license-badge]][license]
</div>

[gha]: https://github.com/cosmos/sp1-ics07-tendermint/actions
[gha-badge]: https://github.com/cosmos/sp1-ics07-tendermint/actions/workflows/e2e.yml/badge.svg
[sp1]: https://github.com/succinctlabs/sp1
[sp1-badge]: https://img.shields.io/badge/Built%20with-SP1-1D4351.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

This is a WIP example of an [ICS-07](https://github.com/cosmos/ibc/tree/main/spec/client/ics-007-tendermint-client) IBC light client on Ethereum powered by [SP1](https://github.com/succinctlabs/sp1) and [`ibc-rs`](https://github.com/cosmos/ibc-rs).

![Light Mode Diagram](./sp1-ics07-tendermint-light.svg#gh-light-mode-only)![Dark Mode Diagram](./sp1-ics07-tendermint-dark.svg#gh-dark-mode-only)

## Table of Contents

<!-- TOC -->

- [SP1 ICS07-Tendermint IBC Light Client](#sp1-ics07-tendermint-ibc-light-client)
    - [Table of Contents](#table-of-contents)
    - [Overview](#overview)
        - [Project Structure](#project-structure)
        - [Programs](#programs)
    - [Requirements](#requirements)
    - [Build the programs](#build-the-programs)
    - [Run ICS-07 Tendermint Light Client End to End](#run-ics-07-tendermint-light-client-end-to-end)
    - [EVM-Compatible Proof Generation & Verification](#evm-compatible-proof-generation--verification)
        - [Solidity Proof Verification](#solidity-proof-verification)
    - [End to End Testing](#end-to-end-testing)

<!-- /TOC -->

## Overview

`sp1-ics07-tendermint` is an example ZK IBC tendermint light client on Ethereum.

### Project Structure

This project is structured as a cargo workspace with the following directories:
* The `contracts` directory contains a Solidity contract that implements the ICS-07 Tendermint light client which can verify SP1 proofs. This is a [`foundry`](https://github.com/foundry-rs/foundry) project, and not a part of the cargo workspace.
* The `operator` directory contains a Rust program that interacts with the Solidity contract. It fetches the latest header (although it could also fetch historical headers) and generates a proof of the update using `ibc-rs`, and then updates the contract with the proof. It also contains several scripts to generate fixtures and proofs for testing.
* The `programs` directory contains the SP1 programs that are compiled to RiscV and run on the SP1's zkVM.
* The `packages` directory contains a shared rust library that is used by the `operator` and `programs` directories.

### Programs

This project contains the following programs

|     **Programs**    |                                                                                                                                     **Description**                                                                                                                                     | **Status** |
|:-------------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:----------:|
|   `update-client`   | Once the initial client state and consensus state are submitted, future consensus states can be added to the client by submitting IBC Headers. These headers contain all necessary information to run the Comet BFT Light Client protocol. Also supports partial misbehavior check.     |      ✅     |
|     `membership`    | As consensus states are added to the client, they can be used for proof verification by relayers wishing to prove packet flow messages against a particular height on the counterparty. This uses the `verify_membership` and `verify_non_membership` methods on the tendermint client. |      ✅     |
| `uc-and-membership` | This is a program that combines `update-client` and `membership` to update the client, and prove membership of packet flow messages against the new consensus state.                                                                                                                    |      ✅     |
|    `misbehaviour`   | In case, the malicious subset of the validators exceeds the trust level of the client; then the client can be deceived into accepting invalid blocks and the connection is no longer secure. The tendermint client has some mitigations in place to prevent this.                       |      ⏳     |
|   `upgrade-client`   | The chain which this light client is tracking can elect to write a special pre-determined key in state to allow the light client to update its client state (e.g. with a new chain ID or revision).                                                                                    |      ⏳     |

## Requirements

- [Rust](https://rustup.rs/)
- [SP1](https://succinctlabs.github.io/sp1/getting-started/install.html)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Bun](https://bun.sh/)
- [Just](https://just.systems/man/en/) (recommended)

Foundry typically uses git submodules to manage contract dependencies, but this template uses Node.js packages (via Bun) because submodules don't scale. You can install the contracts dependencies by running the following command:

```sh
bun install
```

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

    ```.env
    CONTRACT_ADDRESS=<CONTRACT_ADDRESS>
    ```

4. Run the Tendermint operator.
    
    To run the operator, you need to select the prover type for SP1. This is set in the `.env` file with the `SP1_PROVER` value (`network|local|mock`).
    If you run the operator with the `network` prover, you need to provide your SP1 network private key with `SP1_PRIVATE_KEY=0xyourprivatekey` in `.env`.
    
    ```sh
    just operator
    ```

## EVM-Compatible Proof Generation & Verification

> [!WARNING]
> You will need at least 128GB RAM to generate the PLONK proof.

Here, I will show you how to generate a proof to be used in the fixtures for the foundry tests. You can do this locally or by using the SP1 prover network. To do this on your local machine, run the following command:

```sh
just fixtures local
```

To use the SP1 prover network, set `SP1_PROVER=network` and provide your SP1 network private key with `SP1_PRIVATE_KEY="0xyourprivatekey` in the `.env` file. 
After this, you can run the following command:

```sh
just fixtures network
```

### Solidity Proof Verification

After generating the verify the proof with the SP1 EVM verifier.

```sh
just test-foundry
```

## End to End Testing

There are several end-to-end tests in the `e2e/interchaintestv8` directory. These tests are written in Go and use the [`interchaintest`](https://github.com/strangelove-ventures/interchaintest) library. It spins up a local Ethereum and a Tendermint network and runs the tests found in [`e2e/interchaintestv8/sp1_ics07_test.go`](e2e/interchaintestv8/sp1_ics07_test.go). Some of the tests use the prover network to generate the proofs, so you need to provide your SP1 network private key to `.env` for these tests to pass.

> [!NOTE]
> If you are running on a Mac with an M chip, you will need to do the following:
> - Set up Rosetta
> - Enable Rosetta for Docker (in Docker Desktop: Settings -> General -> enable "Use Rosetta for x86_64/amd64 emulation on Apple Silicon")
> - Pull the foundry image with the following command:
> 
>     ```sh
>     docker pull --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest
>     ```

To run the tests, run the following command:

```sh
just test-e2e $TEST_NAME
```

Where `$TEST_NAME` is the name of the test you want to run, for example:

```sh
just test-e2e TestDeploy
```
