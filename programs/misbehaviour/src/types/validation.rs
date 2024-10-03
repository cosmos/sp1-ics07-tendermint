//! Contains types and traits for `verify_misbehaviour` validation within the program.

use ibc_client_tendermint::{
    client_state::ClientState as ClientStateWrapper,
    consensus_state::ConsensusState as ConsensusStateWrapper, types::ConsensusState,
};
use ibc_core_client::context::{ClientValidationContext, ExtClientValidationContext};
use ibc_core_handler_types::error::ContextError;
use ibc_primitives::Timestamp;
use sp1_ics07_tendermint_solidity::IICS07TendermintMsgs::Env;
use std::collections::HashMap;

/// The client validation context.
pub struct MisbehaviourValidationContext<'a, 'b> {
    env: &'a Env,
    trusted_consensus_states: HashMap<u64, &'b ConsensusState>,
}

impl<'a, 'b> MisbehaviourValidationContext<'a, 'b> {
    /// Create a new instance of the client validation context.
    #[must_use]
    pub const fn new(
        env: &'a Env,
        trusted_consensus_states: HashMap<u64, &'b ConsensusState>,
    ) -> Self {
        Self {
            env,
            trusted_consensus_states,
        }
    }
}

impl<'a, 'b> ClientValidationContext for MisbehaviourValidationContext<'a, 'b> {
    type ClientStateRef = ClientStateWrapper;
    type ConsensusStateRef = ConsensusStateWrapper;

    fn consensus_state(
        &self,
        client_cons_state_path: &ibc_core_host_types::path::ClientConsensusStatePath,
    ) -> Result<Self::ConsensusStateRef, ContextError> {
        let height = client_cons_state_path.revision_height;
        let trusted_consensus_state = self.trusted_consensus_states[&height];

        Ok(trusted_consensus_state.clone().into())
    }

    fn client_state(
        &self,
        _client_id: &ibc_core_host_types::identifiers::ClientId,
    ) -> Result<Self::ClientStateRef, ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }

    fn client_update_meta(
        &self,
        _client_id: &ibc_core_host_types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<(Timestamp, ibc_core_client::types::Height), ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }
}

impl<'a, 'b> ExtClientValidationContext for MisbehaviourValidationContext<'a, 'b> {
    fn host_timestamp(&self) -> Result<Timestamp, ContextError> {
        Ok(Timestamp::from_nanoseconds(self.env.now * 1_000_000_000))
    }

    fn host_height(&self) -> Result<ibc_core_client::types::Height, ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }

    fn consensus_state_heights(
        &self,
        _client_id: &ibc_core_host_types::identifiers::ClientId,
    ) -> Result<Vec<ibc_core_client::types::Height>, ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }

    fn next_consensus_state(
        &self,
        _client_id: &ibc_core_host_types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<Option<Self::ConsensusStateRef>, ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }

    fn prev_consensus_state(
        &self,
        _client_id: &ibc_core_host_types::identifiers::ClientId,
        _height: &ibc_core_client::types::Height,
    ) -> Result<Option<Self::ConsensusStateRef>, ContextError> {
        // not needed by the `verify_misbehaviour` function
        unimplemented!()
    }
}
