//! Containes types used in the program.

use ibc_client_tendermint::{
    client_state::ClientState as ClientStateWrapper,
    consensus_state::ConsensusState as ConsensusStateWrapper, types::ConsensusState,
};
use ibc_core_client::context::{ClientValidationContext, ExtClientValidationContext};
use ibc_core_handler_types::error::ContextError;
use ibc_primitives::Timestamp;
use tendermint_light_client_verifier::types::TrustThreshold;

/// The environment passed to the program.
#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct Env {
    /// The chain ID of the chain that the client is tracking.
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

/// The client validation context.
pub struct ClientValidationCtx {
    env: Env,
    trusted_consensus_state: ConsensusState,
}

impl ClientValidationCtx {
    /// Create a new instance of the client validation context.
    #[must_use]
    pub const fn new(env: Env, trusted_consensus_state: ConsensusState) -> Self {
        Self {
            env,
            trusted_consensus_state,
        }
    }
}

impl ClientValidationContext for ClientValidationCtx {
    type ClientStateRef = ClientStateWrapper;
    type ConsensusStateRef = ConsensusStateWrapper;

    fn client_state(
        &self,
        _client_id: &ibc_core_host::types::identifiers::ClientId,
    ) -> Result<Self::ClientStateRef, ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }

    fn consensus_state(
        &self,
        _client_cons_state_path: &ibc_core_host::types::path::ClientConsensusStatePath,
    ) -> Result<Self::ConsensusStateRef, ContextError> {
        // This is the trusted consensus state, whether or not it corresponds to the
        // consensus state path will be checked in solidity.
        Ok(self.trusted_consensus_state.clone().into())
    }

    fn client_update_meta(
        &self,
        _client_id: &ibc_core_host::types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<(Timestamp, ibc_core_client::types::Height), ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }
}

impl ExtClientValidationContext for ClientValidationCtx {
    fn host_timestamp(&self) -> Result<Timestamp, ContextError> {
        Ok(Timestamp::from_nanoseconds(self.env.now).unwrap())
    }

    fn host_height(&self) -> Result<ibc_core_client::types::Height, ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }

    fn consensus_state_heights(
        &self,
        _client_id: &ibc_core_host::types::identifiers::ClientId,
    ) -> Result<Vec<ibc_core_client::types::Height>, ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }

    fn next_consensus_state(
        &self,
        _client_id: &ibc_core_host::types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<Option<Self::ConsensusStateRef>, ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }

    fn prev_consensus_state(
        &self,
        _client_id: &ibc_core_host::types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<Option<Self::ConsensusStateRef>, ContextError> {
        // not needed by the `verify_header` function
        unimplemented!()
    }
}
