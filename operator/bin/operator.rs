use alloy_sol_types::{SolCall, SolValue};
use ibc_client_tendermint::types::Header;
use ibc_core_client_types::Height as IbcHeight;
use log::{debug, info};
use sp1_ics07_tendermint_operator::{
    contract::ContractClient, util::TendermintRPCClient, SP1ICS07TendermintProver,
};
use sp1_ics07_tendermint_shared::types::ics07_tendermint::{
    ClientState, ConsensusState, SP1ICS07Tendermint,
};
use sp1_ics07_tendermint_update_client::types::validation::Env;
use sp1_sdk::utils::setup_logger;

/// An implementation of a Tendermint Light Client operator that will poll an onchain Tendermint
/// light client and generate a proof of the transition from the latest block in the contract to the
/// latest block on the chain. Then, submits the proof to the contract and updates the contract with
/// the latest block hash and height.
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();
    setup_logger();

    // Instantiate a contract client to interact with the deployed Solidity Tendermint contract.
    let contract_client = ContractClient::default();

    // Instantiate a Tendermint prover based on the environment variable.
    let tendermint_rpc_client = TendermintRPCClient::default();
    let prover = SP1ICS07TendermintProver::new();

    loop {
        let contract_client_state_call = SP1ICS07Tendermint::clientStateCall {}.abi_encode();
        let contract_client_state_bz = contract_client.read(contract_client_state_call).await?;
        let contract_client_state =
            ClientState::abi_decode(&contract_client_state_bz, true).unwrap();
        // Read the existing trusted header hash from the contract.
        let trusted_revision_number = contract_client_state.latest_height.revision_number;
        let trusted_block_height = contract_client_state.latest_height.revision_height;
        if trusted_block_height == 0 {
            panic!(
                "No trusted height found on the contract. Something is wrong with the contract."
            );
        }

        // Get trusted consensus state from the contract.
        let trusted_consensus_state_call = SP1ICS07Tendermint::consensusStatesCall {
            _0: trusted_block_height,
        }
        .abi_encode();
        let trusted_consensus_state_bz = contract_client.read(trusted_consensus_state_call).await?;
        let trusted_consensus_state =
            ConsensusState::abi_decode(&trusted_consensus_state_bz, true).unwrap();

        let chain_latest_block_height = tendermint_rpc_client.get_latest_block_height().await;
        let (trusted_light_block, target_light_block) = tendermint_rpc_client
            .get_light_blocks(trusted_block_height, chain_latest_block_height)
            .await;

        let chain_id = target_light_block.signed_header.header.chain_id.to_string();
        let proposed_header = Header {
            signed_header: target_light_block.signed_header,
            validator_set: target_light_block.validators,
            trusted_height: IbcHeight::new(trusted_revision_number, chain_latest_block_height)
                .unwrap(),
            trusted_next_validator_set: trusted_light_block.next_validators,
        };

        let contract_env = Env {
            chain_id,
            trust_threshold: contract_client_state.trust_level,
            trusting_period: contract_client_state.trusting_period,
            now: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos() as u64,
        };

        // Generate a proof of the transition from the trusted block to the target block.
        let proof_data = prover.generate_ics07_update_client_proof(
            &trusted_consensus_state,
            &proposed_header,
            &contract_env,
        );

        // Construct the on-chain call and relay the proof to the contract.
        let proof_as_bytes = hex::decode(&proof_data.proof.encoded_proof).unwrap();
        let verify_tendermint_proof_call_data =
            SP1ICS07Tendermint::verifyIcs07UpdateClientProofCall {
                publicValues: proof_data.public_values.to_vec().into(),
                proof: proof_as_bytes.into(),
            }
            .abi_encode();
        contract_client
            .send(verify_tendermint_proof_call_data)
            .await?;

        info!(
            "Updated the latest block of Tendermint light client at address {} from block {} to block {}.",
            contract_client.contract, trusted_block_height, chain_latest_block_height
        );

        // Sleep for 60 seconds.
        debug!("sleeping for 60 seconds");
        tokio::time::sleep(std::time::Duration::from_secs(60)).await;
    }
}
