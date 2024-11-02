//! Runner for generating `update_client` fixtures

use crate::{
    cli::command::{fixtures::UpdateClientCmd, OutputPath},
    runners::genesis::SP1ICS07TendermintGenesis,
};
use alloy_sol_types::SolValue;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_prover::{
    programs::UpdateClientProgram, prover::SP1ICS07TendermintProver,
};
use sp1_ics07_tendermint_solidity::{
    IICS07TendermintMsgs::{ClientState, ConsensusState, Env},
    ISP1Msgs::SP1Proof,
    IUpdateClientMsgs::{MsgUpdateClient, UpdateClientOutput},
};
use sp1_ics07_tendermint_utils::{light_block::LightBlockExt, rpc::TendermintRpcExt};
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::HttpClient;

/// The fixture data to be used in [`UpdateClientProgram`] tests.
#[serde_with::serde_as]
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07UpdateClientFixture {
    /// The genesis data.
    #[serde(flatten)]
    genesis: SP1ICS07TendermintGenesis,
    /// The encoded target consensus state.
    #[serde_as(as = "serde_with::hex::Hex")]
    target_consensus_state: Vec<u8>,
    /// Target height.
    target_height: u32,
    /// The encoded update client message.
    #[serde_as(as = "serde_with::hex::Hex")]
    update_msg: Vec<u8>,
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

    let genesis = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block,
        args.trust_options.trusting_period,
        args.trust_options.trust_level,
    )
    .await?;

    let trusted_consensus_state =
        ConsensusState::abi_decode(&genesis.trusted_consensus_state, false)?;
    let trusted_client_state = ClientState::abi_decode(&genesis.trusted_client_state, false)?;

    let proposed_header = target_light_block.into_header(&trusted_light_block);
    let contract_env = Env {
        chainId: trusted_light_block.chain_id()?.to_string(),
        trustThreshold: trusted_client_state.trustLevel,
        trustingPeriod: trusted_client_state.trustingPeriod,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs(),
    };

    // Generate a header update proof for the specified blocks.
    let proof_data =
        uc_prover.generate_proof(&trusted_consensus_state, &proposed_header, &contract_env);

    let output = UpdateClientOutput::abi_decode(proof_data.public_values.as_slice(), false)?;

    let update_msg = MsgUpdateClient {
        sp1Proof: SP1Proof::new(
            &uc_prover.vkey.bytes32(),
            proof_data.bytes(),
            proof_data.public_values.to_vec(),
        ),
    };

    let fixture = SP1ICS07UpdateClientFixture {
        genesis,
        target_consensus_state: output.newConsensusState.abi_encode(),
        target_height: args.target_block,
        update_msg: update_msg.abi_encode(),
    };

    match args.output_path {
        OutputPath::File(path) => {
            // Save the proof data to the file path.
            std::fs::write(PathBuf::from(path), serde_json::to_string_pretty(&fixture)?)?;
        }
        OutputPath::Stdout => {
            println!("{}", serde_json::to_string_pretty(&fixture)?);
        }
    }

    Ok(())
}
