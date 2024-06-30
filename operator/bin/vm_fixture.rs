use alloy_sol_types::{SolType, SolValue};
use clap::Parser;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_operator::SP1ICS07TendermintProgram;
use sp1_ics07_tendermint_operator::{
    rpc::TendermintRPCClient, SP1ICS07TendermintProver, UpdateClientProgram,
    VerifyMembershipProgram,
};
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::ConsensusState as SolConsensusState;
use sp1_sdk::{utils::setup_logger, HashableKey};
use sp1_sdk::{MockProver, Prover};
use std::{env, path::PathBuf};
use tendermint_rpc::Client;

/// The arguments for the fixture executable.
#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct FixtureArgs {
    /// Trusted block.
    /// Use the latest block height if not specified.
    #[clap(long)]
    trusted_block: Option<u32>,

    /// Path to the provable data.
    #[clap(long, env)]
    path: String,

    /// Fixture path.
    #[clap(long, default_value = "../contracts/fixtures")]
    fixture_path: String,
}

/// The fixture data to be used in [`UpdateClientProgram`] tests.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07VerifyMembershipFixture {
    /// The proof height.
    proof_height: u32,
    /// The encoded trusted consensus state.
    trusted_consensus_state: String,
    /// The encoded commitment root.
    commitment_root: String,
    /// The encoded key for the [`UpdateClientProgram`].
    update_client_vkey: String,
    /// The encoded key for the [`VerifyMembershipProgram`].
    verify_membership_vkey: String,
    /// The encoded public values.
    public_values: String,
    /// The encoded proof.
    proof: String,
    /// Hex-encoded value.
    value: String,
}

/// The public values encoded as a tuple that can be easily deserialized inside Solidity.
type VerifyMembershipOutput = alloy_sol_types::sol! {
    tuple(bytes32, string, bytes)
};

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
/// Example:
/// ```
/// RUST_LOG=info cargo run --bin fixture --release -- --trusted-block=1 --target-block=5
/// ```
/// The fixture will be written to the path: ./contracts/fixtures/fixture.json
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();
    setup_logger();

    let args = FixtureArgs::parse();

    let tm_rpc_client = TendermintRPCClient::default();
    let tendermint_prover = SP1ICS07TendermintProver::<VerifyMembershipProgram>::default();

    let trusted_light_block = tm_rpc_client.get_light_block(args.trusted_block).await?;
    let trusted_height: u32 = trusted_light_block.height().value().try_into()?;
    if args.trusted_block.is_none() {
        log::info!("Latest block height: {}", trusted_height);
    }

    let commitment_root =
        CommitmentRoot::from_bytes(trusted_light_block.signed_header.header.app_hash.as_bytes());
    let trusted_consensus_state = ConsensusState {
        timestamp: trusted_light_block.signed_header.header.time,
        root: CommitmentRoot::from_bytes(
            trusted_light_block.signed_header.header.app_hash.as_bytes(),
        ),
        next_validators_hash: trusted_light_block
            .signed_header
            .header
            .next_validators_hash,
    };

    let res = tm_rpc_client
        .as_tm_client()
        .abci_query(
            Some("store/ibc/key".to_string()),
            args.path.as_bytes(),
            Some(trusted_height.into()),
            true,
        )
        .await?;

    assert_eq!(u32::try_from(res.height.value())?, trusted_height);
    assert_eq!(res.key.as_slice(), args.path.as_bytes());
    let vm_proof = res.proof.unwrap();
    let vm_proof_bytes = serde_cbor::to_vec(&vm_proof).unwrap();
    let value = res.value;

    // Generate a header update proof for the specified blocks.
    let proof_data = tendermint_prover.generate_proof(
        commitment_root.as_bytes(),
        &args.path,
        vm_proof_bytes,
        &value,
    );

    let bytes = proof_data.public_values.as_slice();
    let (app_hash, output_path, output_val) =
        VerifyMembershipOutput::abi_decode(bytes, false).unwrap();
    assert_eq!(output_path, args.path);
    assert_eq!(output_val, value);
    assert_eq!(app_hash.as_slice(), commitment_root.as_bytes());

    let fixture = SP1ICS07VerifyMembershipFixture {
        proof_height: trusted_height,
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        commitment_root: hex::encode(commitment_root.as_bytes()),
        update_client_vkey: MockProver::new()
            .setup(UpdateClientProgram::ELF)
            .1
            .bytes32(),
        verify_membership_vkey: tendermint_prover.vkey.bytes32(),
        public_values: proof_data.public_values.bytes(),
        proof: proof_data.bytes(),
        value: hex::encode(value),
    };

    // Save the proof data to the file path.
    let fixture_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(args.fixture_path);

    let sp1_prover_type = env::var("SP1_PROVER");
    if sp1_prover_type.as_deref() == Ok("mock") {
        std::fs::write(
            fixture_path.join("mock_verify_membership_fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    } else {
        std::fs::write(
            fixture_path.join("verify_membership_fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    }

    Ok(())
}
