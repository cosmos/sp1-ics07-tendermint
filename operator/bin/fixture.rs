use alloy_sol_types::SolValue;
use clap::Parser;
use ibc_client_tendermint::types::{ConsensusState, Header};
use ibc_core_client_types::Height as IbcHeight;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::identifiers::ChainId;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_operator::{util::TendermintRPCClient, SP1ICS07TendermintProver};
use sp1_ics07_tendermint_shared::types::ics07_tendermint::{
    ClientState, ConsensusState as SolConsensusState, Height, TrustThreshold,
};
use sp1_ics07_tendermint_update_client::types::{
    output::SP1ICS07TendermintOutput, validation::Env,
};
use sp1_sdk::{utils::setup_logger, HashableKey};
use std::{env, path::PathBuf, str::FromStr};

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct FixtureArgs {
    /// Trusted block.
    #[clap(long)]
    trusted_block: u64,

    /// Target block.
    #[clap(long, env)]
    target_block: u64,

    /// Fixture path.
    #[clap(long, default_value = "../contracts/fixtures")]
    fixture_path: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07TendermintFixture {
    // The encoded trusted client state.
    trusted_client_state: String,
    // The encoded trusted consensus state.
    trusted_consensus_state: String,
    // The encoded target consensus state.
    target_consensus_state: String,
    // Target height.
    target_height: u64,
    vkey: String,
    public_values: String,
    proof: String,
}

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
    let tendermint_prover = SP1ICS07TendermintProver::new();

    let (trusted_light_block, target_light_block) = tendermint_rpc_client
        .get_light_blocks(args.trusted_block, args.target_block)
        .await;
    let chain_id = ChainId::from_str(trusted_light_block.signed_header.header.chain_id.as_str())?;

    let trusted_client_state = ClientState {
        chain_id: chain_id.to_string(),
        trust_level: TrustThreshold {
            numerator: 1,
            denominator: 3,
        },
        latest_height: Height {
            revision_number: chain_id.revision_number(),
            revision_height: args.trusted_block,
        },
        is_frozen: false,
        // 2 weeks in nanoseconds
        trusting_period: 14 * 24 * 60 * 60 * 1_000_000_000,
        unbonding_period: 14 * 24 * 60 * 60 * 1_000_000_000,
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
    let proposed_header = Header {
        signed_header: target_light_block.signed_header,
        validator_set: target_light_block.validators,
        trusted_height: IbcHeight::new(
            trusted_client_state.latest_height.revision_number,
            trusted_client_state.latest_height.revision_height,
        )
        .unwrap(),
        trusted_next_validator_set: trusted_light_block.next_validators,
    };
    let contract_env = Env {
        chain_id: chain_id.to_string(),
        trust_threshold: trusted_client_state.trust_level.clone(),
        trusting_period: trusted_client_state.trusting_period,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64,
    };

    // Generate a header update proof for the specified blocks.
    let proof_data = tendermint_prover.generate_ics07_update_client_proof(
        &trusted_consensus_state.clone().into(),
        &proposed_header,
        &contract_env,
    );

    let bytes = proof_data.public_values.as_slice();
    let output = SP1ICS07TendermintOutput::abi_decode(bytes, false).unwrap();

    let fixture = SP1ICS07TendermintFixture {
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        target_consensus_state: hex::encode(output.new_consensus_state.abi_encode()),
        target_height: args.target_block,
        vkey: tendermint_prover.vkey.bytes32(),
        public_values: proof_data.public_values.bytes(),
        proof: proof_data.bytes(),
    };

    // Save the proof data to the file path.
    let fixture_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(args.fixture_path);

    // TODO: Change to prover.id
    let sp1_prover_type = env::var("SP1_PROVER");
    if sp1_prover_type.as_deref() == Ok("mock") {
        std::fs::write(
            fixture_path.join("mock_fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    } else {
        std::fs::write(
            fixture_path.join("fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    }

    Ok(())
}
