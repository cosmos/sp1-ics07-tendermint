//! Runner for generating `misbehaviour` fixtures

use crate::{
    cli::command::{fixtures::MisbehaviourCmd, OutputPath},
    runners::genesis::SP1ICS07TendermintGenesis,
};
use alloy_sol_types::SolValue;
use ibc_client_tendermint_types::Misbehaviour;
use ibc_proto::ibc::lightclients::tendermint::v1::Misbehaviour as RawMisbehaviour;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_prover::{
    programs::MisbehaviourProgram, prover::SP1ICS07TendermintProver,
};
use sp1_ics07_tendermint_solidity::{
    IICS07TendermintMsgs::{ClientState, ConsensusState, Env},
    IMisbehaviourMsgs::MsgSubmitMisbehaviour,
    ISP1Msgs::SP1Proof,
};
use sp1_ics07_tendermint_utils::{light_block::LightBlockExt, rpc::TendermintRpcExt};
use sp1_sdk::HashableKey;
use std::path::PathBuf;
use tendermint_rpc::HttpClient;

/// The fixture data to be used in [`SP1ICS07SubmitMisbehaviourFixture`] tests.
#[serde_with::serde_as]
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07SubmitMisbehaviourFixture {
    /// The genesis data.
    #[serde(flatten)]
    genesis: SP1ICS07TendermintGenesis,

    /// The encoded submit misbehaviour client message.
    #[serde_as(as = "serde_with::hex::Hex")]
    submit_msg: Vec<u8>,
}

/// Writes the proof data for misbehaviour to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: MisbehaviourCmd) -> anyhow::Result<()> {
    let path = args.misbehaviour_path;
    let misbehaviour_bz = std::fs::read(path)?;
    // deserialize from json
    let raw_misbehaviour: RawMisbehaviour = serde_json::from_slice(&misbehaviour_bz)?;

    let tm_rpc_client = HttpClient::from_env();

    // get light block for trusted height of header 1
    #[allow(clippy::cast_possible_truncation)]
    let trusted_light_block_1 = tm_rpc_client
        .get_light_block(Some(
            raw_misbehaviour
                .header_1
                .as_ref()
                .unwrap()
                .trusted_height
                .unwrap()
                .revision_height as u32,
        ))
        .await?;
    #[allow(clippy::cast_possible_truncation)]
    // get light block for trusted height of header 2
    let trusted_light_block_2 = tm_rpc_client
        .get_light_block(Some(
            raw_misbehaviour
                .header_2
                .as_ref()
                .unwrap()
                .trusted_height
                .unwrap()
                .revision_height as u32,
        ))
        .await?;

    // use trusted light block 1 to instantiate a new SP1 tendermint client with light block 1 as initial trusted consensus state
    let genesis_1 = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block_1,
        args.trust_options.trusting_period,
        args.trust_options.trust_level,
    )
    .await?;
    // use trusted light block 2 to instantiate a new SP1 tendermint client with light block 2 as initial trusted consensus state
    let genesis_2 = SP1ICS07TendermintGenesis::from_env(
        &trusted_light_block_2,
        args.trust_options.trusting_period,
        args.trust_options.trust_level,
    )
    .await?;

    // use the clients to convert the Tendermint light blocks into the IBC Tendermint trusted consensus states
    let trusted_consensus_state_1 =
        ConsensusState::abi_decode(&genesis_1.trusted_consensus_state, false)?;
    let trusted_consensus_state_2 =
        ConsensusState::abi_decode(&genesis_2.trusted_consensus_state, false)?;

    // use the client state from genesis_2 as the client state since they will both be the same
    let trusted_client_state_2 = ClientState::abi_decode(&genesis_2.trusted_client_state, false)?;

    let verify_misbehaviour_prover = SP1ICS07TendermintProver::<MisbehaviourProgram>::default();

    // construct contract env from the client state, which will be used by the light client contract
    let contract_env = Env {
        chainId: trusted_light_block_2.chain_id()?.to_string(),
        trustThreshold: trusted_client_state_2.trustLevel,
        trustingPeriod: trusted_client_state_2.trustingPeriod,
        now: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs(),
    };

    let misbehaviour: Misbehaviour = Misbehaviour::try_from(raw_misbehaviour).unwrap();
    let proof_data = verify_misbehaviour_prover.generate_proof(
        &contract_env,
        &misbehaviour,
        &trusted_consensus_state_1,
        &trusted_consensus_state_2,
    );

    let submit_msg = MsgSubmitMisbehaviour {
        sp1Proof: SP1Proof::new(
            &verify_misbehaviour_prover.vkey.bytes32(),
            proof_data.bytes(),
            proof_data.public_values.to_vec(),
        ),
    };

    let fixture = SP1ICS07SubmitMisbehaviourFixture {
        genesis: genesis_2,
        submit_msg: submit_msg.abi_encode(),
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
