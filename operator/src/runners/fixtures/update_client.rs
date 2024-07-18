//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::fixtures::UpdateClientCmd,
    helpers::light_block::LightBlockExt,
    programs::{
        MembershipProgram, SP1Program, UpdateClientAndMembershipProgram, UpdateClientProgram,
    },
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRpcExt,
};
use alloy_sol_types::SolValue;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{Env, UpdateClientOutput};
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::HttpClient;

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
    /// The encoded key for the [`MembershipProgram`].
    membership_vkey: String,
    /// The encoded key for the [`UpdateClientAndMembershipProgram`].
    uc_and_membership_vkey: String,
    /// The encoded public values.
    public_values: String,
    /// The encoded proof.
    proof: String,
}

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: UpdateClientCmd) -> anyhow::Result<()> {
    assert!(
        args.trusted_block < args.target_block,
        "The target block must be greater than the trusted block"
    );

    let tm_rpc_client = HttpClient::from_env();
    let uc_prover = SP1ICS07TendermintProver::<UpdateClientProgram>::default();

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.trusted_block))
        .await?;
    let target_light_block = tm_rpc_client
        .get_light_block(Some(args.target_block))
        .await?;

    let unbonding_period = tm_rpc_client
        .sdk_staking_params()
        .await?
        .unbonding_time
        .ok_or_else(|| anyhow::anyhow!("No unbonding time found"))?
        .seconds
        .try_into()?;

    let trusted_client_state =
        trusted_light_block.to_sol_client_state(args.trust_level.try_into()?, unbonding_period)?;
    let trusted_consensus_state = trusted_light_block.to_consensus_state().into();
    let proposed_header = target_light_block.into_header(&trusted_light_block);
    let contract_env = Env {
        chain_id: trusted_light_block.chain_id()?.to_string(),
        trust_threshold: trusted_client_state.trust_level.clone(),
        trusting_period: trusted_client_state.trusting_period,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs(),
    };

    // Generate a header update proof for the specified blocks.
    let proof_data =
        uc_prover.generate_proof(&trusted_consensus_state, &proposed_header, &contract_env);

    let bytes = proof_data.public_values.as_slice();
    let output = UpdateClientOutput::abi_decode(bytes, false).unwrap();

    let fixture = SP1ICS07UpdateClientFixture {
        trusted_consensus_state: hex::encode(trusted_consensus_state.abi_encode()),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        target_consensus_state: hex::encode(output.new_consensus_state.abi_encode()),
        target_height: args.target_block,
        update_client_vkey: uc_prover.vkey.bytes32(),
        membership_vkey: MembershipProgram::get_vkey().bytes32(),
        uc_and_membership_vkey: UpdateClientAndMembershipProgram::get_vkey().bytes32(),
        public_values: proof_data.public_values.bytes(),
        proof: proof_data.bytes(),
    };

    // Save the proof data to the file path.
    std::fs::write(
        PathBuf::from(args.output_path),
        serde_json::to_string_pretty(&fixture).unwrap(),
    )
    .unwrap();
    Ok(())
}
