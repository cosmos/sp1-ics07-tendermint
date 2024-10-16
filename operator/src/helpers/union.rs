//! Helpers for interacting with union's ics23 library.

use tendermint::merkle::proof::ProofOps;
use union_protos::{
    cosmos::ics23::v1::CommitmentProof as ProtoCommitmentProof,
    ibc::core::commitment::v1::MerkleProof as ProtoMerkleProof,
};
use unionlabs::{
    cosmos::ics23::commitment_proof::CommitmentProof,
    encoding::{DecodeAs, Proto},
    union::ics23::merkle_proof::MerkleProof,
};

/// Converts the rpc proof ops to a union proof.
///
/// # Errors
/// Fails if the proof ops cannot be converted to a union proof.
pub fn convert_to_union_proof(proof_ops: ProofOps) -> anyhow::Result<MerkleProof> {
    let commitment_proofs = proof_ops
        .ops
        .into_iter()
        .map(|op| {
            Ok(ProtoCommitmentProof::from(CommitmentProof::decode_as::<
                Proto,
            >(&op.data)?))
        })
        .collect::<anyhow::Result<_>>()?;

    Ok(MerkleProof::try_from(ProtoMerkleProof {
        proofs: commitment_proofs,
    })?)
}
