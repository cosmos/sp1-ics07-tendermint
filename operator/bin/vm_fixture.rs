use alloy_sol_types::{SolType, SolValue};
use clap::Parser;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::identifiers::ChainId;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_operator::SP1ICS07TendermintProgram;
use sp1_ics07_tendermint_operator::{
    util::TendermintRPCClient, SP1ICS07TendermintProver, UpdateClientProgram,
    VerifyMembershipProgram,
};
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::{
    ClientState, ConsensusState as SolConsensusState, Height, TrustThreshold,
};
use sp1_sdk::{utils::setup_logger, HashableKey};
use sp1_sdk::{MockProver, Prover};
use std::{env, path::PathBuf, str::FromStr};

/// The arguments for the fixture executable.
#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct FixtureArgs {
    /// Trusted block.
    /// Use the latest block height if not specified.
    #[clap(long)]
    trusted_block: Option<u64>,

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
    /// The encoded trusted client state.
    trusted_client_state: String,
    /// The encoded trusted consensus state.
    trusted_consensus_state: String,
    /// The encoded key for the [`UpdateClientProgram`].
    update_client_vkey: String,
    /// The encoded key for the [`VerifyMembershipProgram`].
    verify_membership_vkey: String,
    /// The encoded public values.
    public_values: String,
    /// The encoded proof.
    proof: String,
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

    let tendermint_rpc_client = TendermintRPCClient::default();
    let tendermint_prover = SP1ICS07TendermintProver::<VerifyMembershipProgram>::default();

    let latest_height = tendermint_rpc_client
        .get_latest_commit()
        .await?
        .result
        .signed_header
        .header
        .height
        .into();
    if args.trusted_block.is_none() {
        log::info!("Latest block height: {}", latest_height);
    }
    let trusted_height = args.trusted_block.unwrap_or(latest_height);

    let trusted_light_block = tendermint_rpc_client
        .get_light_block(trusted_height)
        .await?;
    let chain_id = ChainId::from_str(trusted_light_block.signed_header.header.chain_id.as_str())?;

    let two_weeks_in_nanos = 14 * 24 * 60 * 60 * 1_000_000_000;
    let trusted_client_state = ClientState {
        chain_id: chain_id.to_string(),
        trust_level: TrustThreshold {
            numerator: 1,
            denominator: 3,
        },
        latest_height: Height {
            revision_number: chain_id.revision_number(),
            revision_height: trusted_height,
        },
        is_frozen: false,
        // 2 weeks in nanoseconds
        trusting_period: two_weeks_in_nanos,
        unbonding_period: two_weeks_in_nanos,
    };
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

    // Generate a header update proof for the specified blocks.
    let proof_data = tendermint_prover.generate_proof(
        trusted_light_block.signed_header.header.app_hash.as_bytes(),
        &args.path,
    );

    let bytes = proof_data.public_values.as_slice();
    let _output = VerifyMembershipOutput::abi_decode(bytes, false).unwrap();

    let fixture = SP1ICS07VerifyMembershipFixture {
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        update_client_vkey: MockProver::new()
            .setup(UpdateClientProgram::ELF)
            .1
            .bytes32(),
        verify_membership_vkey: tendermint_prover.vkey.bytes32(),
        public_values: proof_data.public_values.bytes(),
        proof: proof_data.bytes(),
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
