//! Containes types used in the program.

use tendermint_light_client_verifier::types::TrustThreshold;

/// The environment passed to the program.
#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct Env {
    /// The chain ID of the host chain.
    pub chain_id: String,
    /// The client ID of the client that is being updated.
    pub client_id: String,
    /// Fraction of validator overlap needed to update header
    pub trust_threshold: TrustThreshold,
    /// duration of the period since the `LatestTimestamp` during which the
    /// submitted headers are valid for upgrade
    pub trusting_period: u64,
    /// The schema representation is the timestamp in nanoseconds
    pub now: u64,
}
