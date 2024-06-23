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

## Standard Proof Generation

> [!WARNING]
> You will need at least 16GB RAM to generate the default proof.

Generate the proof for your program using the standard prover.

```
cd script
RUST_LOG=info cargo run --bin prove --release
```

## EVM-Compatible Proof Generation & Verification

> [!WARNING]
> You will need at least 128GB RAM to generate the PLONK proof.

Generate the proof that is small enough to be verified on-chain and verifiable by the EVM. This command also generates a fixture that can be used to test the verification of SP1 zkVM proofs inside Solidity.

```
cd script
RUST_LOG=info cargo run --bin prove --release -- --evm
```

### Solidity Proof Verification

After generating the verify the proof with the SP1 EVM verifier.

```
cd ../contracts
forge test -v
```

