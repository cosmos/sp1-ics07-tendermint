//! Contains the runner for the `operator run` command.

use std::env;

use crate::{
    cli::command::operator::Args,
    helpers::{self, light_block::LightBlockWrapper},
    programs::UpdateClientProgram,
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRPCClient,
};
use alloy::providers::ProviderBuilder;
use log::{debug, info};
use reqwest::Url;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{self, Env};
use sp1_sdk::utils::setup_logger;

/// An implementation of a Tendermint Light Client operator that will poll an onchain Tendermint
/// light client and generate a proof of the transition from the latest block in the contract to the
/// latest block on the chain. Then, submits the proof to the contract and updates the contract with
/// the latest block hash and height.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: Args) -> anyhow::Result<()> {
    setup_logger();
    if dotenv::dotenv().is_err() {
        log::warn!("No .env file found");
    }

    let rpc_url = env::var("RPC_URL").expect("RPC_URL not set");
    let contract_address = env::var("CONTRACT_ADDRESS").expect("CONTRACT_ADDRESS not set");

    // Instantiate a Tendermint prover based on the environment variable.
    let wallet = helpers::eth::wallet_from_env();
    let provider = ProviderBuilder::new()
        .with_recommended_fillers()
        .wallet(wallet)
        .on_http(Url::parse(rpc_url.as_str())?);

    let contract = sp1_ics07_tendermint::new(contract_address.parse()?, provider);
    let tendermint_rpc_client = TendermintRPCClient::default();
    let prover = SP1ICS07TendermintProver::<UpdateClientProgram>::default();

    loop {
        let contract_client_state = contract.getClientState().call().await?._0;

        // Read the existing trusted header hash from the contract.
        let trusted_block_height = contract_client_state.latest_height.revision_height;
        assert!(
            trusted_block_height != 0,
            "No trusted height found on the contract. Something is wrong with the contract."
        );

        let trusted_light_block = LightBlockWrapper::new(
            tendermint_rpc_client
                .get_light_block(Some(trusted_block_height))
                .await?,
        );

        // Get trusted consensus state from the trusted light block.
        let trusted_consensus_state = trusted_light_block.to_consensus_state().into();

        let target_light_block =
            LightBlockWrapper::new(tendermint_rpc_client.get_light_block(None).await?);
        let target_height = target_light_block.as_light_block().height().value();

        // Get the proposed header from the target light block.
        let proposed_header = target_light_block.into_header(trusted_light_block.as_light_block());

        let contract_env = Env {
            chain_id: trusted_light_block.chain_id()?.to_string(),
            trust_threshold: contract_client_state.trust_level,
            trusting_period: contract_client_state.trusting_period,
            now: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_nanos()
                .try_into()?,
        };

        // Generate a proof of the transition from the trusted block to the target block.
        let proof_data =
            prover.generate_proof(&trusted_consensus_state, &proposed_header, &contract_env);

        // Construct the on-chain call and relay the proof to the contract.
        let proof_as_bytes = hex::decode(&proof_data.proof.encoded_proof).unwrap();

        contract
            .verifyIcs07UpdateClientProof(
                proof_as_bytes.into(),
                proof_data.public_values.to_vec().into(),
            )
            .send()
            .await?
            .watch()
            .await?;

        info!(
            "Updated the ICS-07 Tendermint light client at address {} from block {} to block {}.",
            contract_address, trusted_block_height, target_height
        );

        if args.only_once {
            info!("Exiting because '--only-once' flag is set.");
            return Ok(());
        }

        // Sleep for 60 seconds.
        debug!("sleeping for 60 seconds");
        tokio::time::sleep(std::time::Duration::from_secs(60)).await;
    }
}
