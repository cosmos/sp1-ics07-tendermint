//! Runner for generating `verify_membership` fixtures

use crate::{
    cli::command::fixtures::VerifyMembershipCmd,
    helpers::light_block::LightBlockWrapper,
    programs::{SP1Program, UpdateClientProgram, VerifyMembershipProgram},
    prover::SP1ICS07TendermintProver,
    rpc::TendermintRPCClient,
};
use alloy_sol_types::SolValue;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{
    ConsensusState as SolConsensusState, VerifyMembershipOutput,
};
use sp1_ics07_tendermint_utils::convert_tm_to_ics_merkle_proof;
use sp1_sdk::HashableKey;
use std::{env, path::PathBuf};
use tendermint_rpc::Client;

/// The fixture data to be used in [`UpdateClientProgram`] tests.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct SP1ICS07VerifyMembershipFixture {
    /// The proof height.
    proof_height: u32,
    /// The encoded trusted client state.
    trusted_client_state: String,
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

/// Writes the proof data for the given trusted and target blocks to the given fixture path.
#[allow(clippy::missing_errors_doc, clippy::missing_panics_doc)]
pub async fn run(args: VerifyMembershipCmd) -> anyhow::Result<()> {
    let tm_rpc_client = TendermintRPCClient::default();
    let verify_mem_prover = SP1ICS07TendermintProver::<VerifyMembershipProgram>::default();

    let trusted_light_block = LightBlockWrapper::new(
        tm_rpc_client
            .get_light_block(Some(args.trusted_block))
            .await?,
    );

    let trusted_client_state = trusted_light_block.to_sol_client_state()?;
    let trusted_consensus_state = trusted_light_block.to_consensus_state();
    let commitment_root_bytes = trusted_consensus_state.root.as_bytes().to_vec();

    let res = tm_rpc_client
        .as_tm_client()
        .abci_query(
            Some("store/ibc/key".to_string()),
            args.key_path.as_bytes(),
            // Proof height should be the block before the target block.
            Some((args.trusted_block - 1).into()),
            true,
        )
        .await?;

    assert_eq!(u32::try_from(res.height.value())? + 1, args.trusted_block);
    assert_eq!(res.key.as_slice(), args.key_path.as_bytes());
    let vm_proof = convert_tm_to_ics_merkle_proof(&res.proof.unwrap())?;
    let value = res.value;
    assert!(!value.is_empty());
    assert!(!vm_proof.proofs.is_empty());

    // Generate a header update proof for the specified blocks.
    let proof_data =
        verify_mem_prover.generate_proof(&commitment_root_bytes, &args.key_path, vm_proof, &value);

    let bytes = proof_data.public_values.as_slice();
    let output = VerifyMembershipOutput::abi_decode(bytes, true).unwrap();
    assert_eq!(output.key_path, args.key_path);
    assert_eq!(output.value.to_vec(), value);
    assert_eq!(output.commitment_root.as_slice(), &commitment_root_bytes);

    let fixture = SP1ICS07VerifyMembershipFixture {
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        proof_height: args.trusted_block,
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        commitment_root: hex::encode(&commitment_root_bytes),
        update_client_vkey: UpdateClientProgram::get_vkey().bytes32(),
        verify_membership_vkey: verify_mem_prover.vkey.bytes32(),
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
