//! Contains the runner for the genesis command.

use crate::{
    cli::command::genesis::Args,
    helpers::light_block::LightBlockExt,
    programs::{
        MembershipProgram, SP1Program, UpdateClientAndMembershipProgram, UpdateClientProgram,
    },
    rpc::TendermintRpcExt,
};
use alloy_sol_types::SolValue;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::ConsensusState as SolConsensusState;
use sp1_sdk::{utils::setup_logger, HashableKey};
use std::{env, path::PathBuf};
use tendermint_rpc::HttpClient;

/// The genesis data for the SP1 ICS07 Tendermint contract.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07TendermintGenesis {
    /// The encoded trusted client state.
    trusted_client_state: String,
    /// The encoded trusted consensus state.
    trusted_consensus_state: String,
    /// The encoded key for [`UpdateClientProgram`].
    update_client_vkey: String,
    /// The encoded key for [`MembershipProgram`].
    membership_vkey: String,
    /// The encoded key for [`UpdateClientAndMembershipProgram`].
    uc_and_membership_vkey: String,
}

/// Creates the `genesis.json` file for the `SP1ICS07Tendermint` contract.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: Args) -> anyhow::Result<()> {
    setup_logger();
    if dotenv::dotenv().is_err() {
        log::warn!("No .env file found");
    }

    let tendermint_rpc_client = HttpClient::from_env();

    let trusted_light_block = tendermint_rpc_client
        .get_light_block(args.trusted_block)
        .await?;
    if args.trusted_block.is_none() {
        log::info!(
            "Latest block height: {}",
            trusted_light_block.height().value()
        );
    }

    let trusted_client_state = trusted_light_block.to_sol_client_state()?;
    let trusted_consensus_state = trusted_light_block.to_consensus_state();
    let genesis = SP1ICS07TendermintGenesis {
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        update_client_vkey: UpdateClientProgram::get_vkey().bytes32(),
        membership_vkey: MembershipProgram::get_vkey().bytes32(),
        uc_and_membership_vkey: UpdateClientAndMembershipProgram::get_vkey().bytes32(),
    };

    let fixture_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(args.genesis_path);
    std::fs::write(
        fixture_path.join("genesis.json"),
        serde_json::to_string_pretty(&genesis).unwrap(),
    )
    .unwrap();

    Ok(())
}
