//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::fixtures::UpdateClientCmd,
    prover::{
        SP1ICS07TendermintProgram, SP1ICS07TendermintProver, UpdateClientProgram,
        VerifyMembershipProgram,
    },
    rpc::TendermintRPCClient,
};
use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::{ConsensusState, Header};
use ibc_core_client_types::Height as IbcHeight;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::identifiers::ChainId;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::{
    ClientState, Height, TrustThreshold,
};
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::{Env, SP1ICS07UpdateClientOutput};
use sp1_sdk::HashableKey;
use sp1_sdk::{MockProver, Prover};
use std::{env, path::PathBuf, str::FromStr};

/// The fixture data to be used in [`UpdateClientProgram`] tests.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07UpdateClientFixture {
    /// The encoded trusted client state.
    trusted_client_state: String,
    /// The encoded trusted consensus state.
    trusted_consensus_state: String,
    /// The encoded target consensus state.
    target_consensus_state: String,
    /// Target height.
    target_height: u32,
    /// The encoded key for the [`UpdateClientProgram`].
    update_client_vkey: String,
    /// The encoded key for the [`VerifyMembershipProgram`].
    verify_membership_vkey: String,
    /// The encoded public values.
    public_values: String,
    /// The encoded proof.
    proof: String,
}

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: UpdateClientCmd) -> anyhow::Result<()> {
    let tendermint_rpc_client = TendermintRPCClient::default();
    let tendermint_prover = SP1ICS07TendermintProver::<UpdateClientProgram>::default();

    let trusted_light_block = tendermint_rpc_client
        .get_light_block(Some(args.trusted_block))
        .await?;
    let target_light_block = tendermint_rpc_client
        .get_light_block(Some(args.target_block))
        .await?;

    let two_weeks_in_nanos = 14 * 24 * 60 * 60 * 1_000_000_000;
    let chain_id = ChainId::from_str(trusted_light_block.signed_header.header.chain_id.as_str())?;
    let trusted_client_state = ClientState {
        chain_id: chain_id.to_string(),
        trust_level: TrustThreshold {
            numerator: 1,
            denominator: 3,
        },
        latest_height: Height {
            revision_number: chain_id.revision_number().try_into()?,
            revision_height: args.trusted_block,
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
    }
    .into();
    let proposed_header = Header {
        signed_header: target_light_block.signed_header,
        validator_set: target_light_block.validators,
        trusted_height: IbcHeight::new(
            trusted_client_state.latest_height.revision_number.into(),
            trusted_client_state.latest_height.revision_height.into(),
        )
        .unwrap(),
        trusted_next_validator_set: trusted_light_block.next_validators,
    };
    let contract_env = Env {
        chain_id: chain_id.to_string(),
        trust_threshold: trusted_client_state.trust_level.clone(),
        trusting_period: trusted_client_state.trusting_period,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_nanos()
            .try_into()?,
    };

    // Generate a header update proof for the specified blocks.
    let proof_data =
        tendermint_prover.generate_proof(&trusted_consensus_state, &proposed_header, &contract_env);

    let bytes = proof_data.public_values.as_slice();
    let output = SP1ICS07UpdateClientOutput::abi_decode(bytes, false).unwrap();

    let fixture = SP1ICS07UpdateClientFixture {
        trusted_consensus_state: hex::encode(trusted_consensus_state.abi_encode()),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        target_consensus_state: hex::encode(output.new_consensus_state.abi_encode()),
        target_height: args.target_block,
        update_client_vkey: tendermint_prover.vkey.bytes32(),
        verify_membership_vkey: MockProver::new()
            .setup(VerifyMembershipProgram::ELF)
            .1
            .bytes32(),
        public_values: proof_data.public_values.bytes(),
        proof: proof_data.bytes(),
    };

    // Save the proof data to the file path.
    let fixture_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(args.fixture_path);

    let sp1_prover_type = env::var("SP1_PROVER");
    if sp1_prover_type.as_deref() == Ok("mock") {
        std::fs::write(
            fixture_path.join("mock_update_client_fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    } else {
        std::fs::write(
            fixture_path.join("update_client_fixture.json"),
            serde_json::to_string_pretty(&fixture).unwrap(),
        )
        .unwrap();
    }

    Ok(())
}
