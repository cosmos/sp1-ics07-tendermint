//! Provides helpers for deriving other types from `LightBlock`.

use ibc_client_tendermint::types::ConsensusState;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::identifiers::ChainId;
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{ClientState, Height, TrustThreshold};
use std::str::FromStr;
use tendermint_light_client_verifier::types::LightBlock;

/// A wrapper around a [`LightBlock`] that provides additional methods.
#[allow(clippy::module_name_repetitions)]
pub struct LightBlockWrapper(LightBlock);

impl LightBlockWrapper {
    /// Create a new instance of the `LightBlockWrapper`.
    #[must_use]
    pub const fn new(light_block: LightBlock) -> Self {
        Self(light_block)
    }

    /// Get the inner `LightBlock`.
    #[must_use]
    pub const fn as_light_block(&self) -> &LightBlock {
        &self.0
    }

    /// Convert the [`LightBlockWrapper`] to a new solidity [`ClientState`].
    ///
    /// # Errors
    /// Returns an error if the chain identifier or height cannot be parsed.
    pub fn to_sol_client_state(&self) -> anyhow::Result<ClientState> {
        let chain_id = ChainId::from_str(self.0.signed_header.header.chain_id.as_str())?;
        let two_weeks_in_nanos = 14 * 24 * 60 * 60 * 1_000_000_000;
        Ok(ClientState {
            chain_id: chain_id.to_string(),
            trust_level: TrustThreshold {
                numerator: 1,
                denominator: 3,
            },
            latest_height: Height {
                revision_number: chain_id.revision_number().try_into()?,
                revision_height: self.0.height().value().try_into()?,
            },
            is_frozen: false,
            trusting_period: two_weeks_in_nanos,
            unbonding_period: two_weeks_in_nanos,
        })
    }

    /// Convert the [`LightBlockWrapper`] to a new [`ConsensusState`].
    #[must_use]
    pub fn to_consensus_state(&self) -> ConsensusState {
        ConsensusState {
            timestamp: self.0.signed_header.header.time,
            root: CommitmentRoot::from_bytes(self.0.signed_header.header.app_hash.as_bytes()),
            next_validators_hash: self.0.signed_header.header.next_validators_hash,
        }
    }
}
