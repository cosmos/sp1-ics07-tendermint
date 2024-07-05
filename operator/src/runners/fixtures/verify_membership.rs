//! Runner for generating `verify_membership` fixtures

use crate::{
    cli::command::fixtures::VerifyMembershipCmd,
    prover::{
        SP1ICS07TendermintProgram, SP1ICS07TendermintProver, UpdateClientProgram,
        VerifyMembershipProgram,
    },
    rpc::TendermintRPCClient,
};
use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::identifiers::ChainId;
use serde::{Deserialize, Serialize};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{
    ClientState, ConsensusState as SolConsensusState, Height, TrustThreshold,
    VerifyMembershipOutput,
};
use sp1_ics07_tendermint_utils::convert_tm_to_ics_merkle_proof;
use sp1_sdk::HashableKey;
use sp1_sdk::{MockProver, Prover};
use std::{env, path::PathBuf, str::FromStr};
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
#[allow(clippy::too_many_lines)] // TODO: Refactor this function
pub async fn run(args: VerifyMembershipCmd) -> anyhow::Result<()> {
    let tm_rpc_client = TendermintRPCClient::default();
    let tendermint_prover = SP1ICS07TendermintProver::<VerifyMembershipProgram>::default();

    let trusted_light_block = tm_rpc_client
        .get_light_block(Some(args.trusted_block))
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
    let commitment_root =
        CommitmentRoot::from_bytes(trusted_light_block.signed_header.header.app_hash.as_bytes());
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
    let vm_proof = res
        .proof
        .as_ref()
        .map(convert_tm_to_ics_merkle_proof)
        .unwrap()
        .unwrap();
    let value = res.value;
    assert!(!value.is_empty());
    assert!(!vm_proof.proofs.is_empty());

    // Generate a header update proof for the specified blocks.
    let proof_data = tendermint_prover.generate_proof(
        commitment_root.as_bytes(),
        &args.key_path,
        vm_proof,
        &value,
    );

    let bytes = proof_data.public_values.as_slice();
    let output = VerifyMembershipOutput::abi_decode(bytes, true).unwrap();
    assert_eq!(output.key_path, args.key_path);
    assert_eq!(output.value.to_vec(), value);
    assert_eq!(
        output.commitment_root.as_slice(),
        commitment_root.as_bytes()
    );

    let fixture = SP1ICS07VerifyMembershipFixture {
        trusted_client_state: hex::encode(trusted_client_state.abi_encode()),
        proof_height: args.trusted_block,
        trusted_consensus_state: hex::encode(
            SolConsensusState::from(trusted_consensus_state).abi_encode(),
        ),
        commitment_root: hex::encode(commitment_root.as_bytes()),
        update_client_vkey: MockProver::new()
            .setup(UpdateClientProgram::ELF)
            .1
            .bytes32(),
        verify_membership_vkey: tendermint_prover.vkey.bytes32(),
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
