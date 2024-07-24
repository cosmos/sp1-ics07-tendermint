//! Provides helpers for deriving other types from `LightBlock`.

use ibc_client_tendermint::types::{ConsensusState, Header};
use ibc_core_client_types::Height as IbcHeight;
use ibc_core_commitment_types::commitment::CommitmentRoot;
use ibc_core_host_types::{error::IdentifierError, identifiers::ChainId};
use sp1_ics07_tendermint_solidity::sp1_ics07_tendermint::{ClientState, Height, TrustThreshold};
use std::str::FromStr;
use tendermint_light_client_verifier::types::LightBlock;

/// Extension trait for [`LightBlock`] that provides additional methods for converting to other
/// types.
#[allow(clippy::module_name_repetitions)]
pub trait LightBlockExt {
    /// Convert the [`LightBlock`] to a new solidity [`ClientState`].
    ///
    /// # Errors
    /// Returns an error if the chain identifier or height cannot be parsed.
    fn to_sol_client_state(
        &self,
        trust_level: TrustThreshold,
        unbonding_period: u32,
        trusting_period: u32,
    ) -> anyhow::Result<ClientState>;
    /// Convert the [`LightBlock`] to a new [`ConsensusState`].
    #[must_use]
    fn to_consensus_state(&self) -> ConsensusState;
    /// Convert the [`LightBlock`] to a new [`Header`].
    ///
    /// # Panics
    /// Panics if the `trusted_height` is zero.
    #[must_use]
    fn into_header(self, trusted_light_block: &LightBlock) -> Header;
    /// Get the chain identifier from the [`LightBlock`].
    ///
    /// # Errors
    /// Returns an error if the chain identifier cannot be parsed.
    fn chain_id(&self) -> Result<ChainId, IdentifierError>;
}

impl LightBlockExt for LightBlock {
    fn to_sol_client_state(
        &self,
        trust_level: TrustThreshold,
        unbonding_period: u32,
        trusting_period: u32,
    ) -> anyhow::Result<ClientState> {
        let chain_id = ChainId::from_str(self.signed_header.header.chain_id.as_str())?;
        Ok(ClientState {
            chain_id: chain_id.to_string(),
            trust_level,
            latest_height: Height {
                revision_number: chain_id.revision_number().try_into()?,
                revision_height: self.height().value().try_into()?,
            },
            is_frozen: false,
            unbonding_period,
            trusting_period,
        })
    }

    fn to_consensus_state(&self) -> ConsensusState {
        ConsensusState {
            timestamp: self.signed_header.header.time,
            root: CommitmentRoot::from_bytes(self.signed_header.header.app_hash.as_bytes()),
            next_validators_hash: self.signed_header.header.next_validators_hash,
        }
    }

    fn into_header(self, trusted_light_block: &LightBlock) -> Header {
        let trusted_revision_number =
            ChainId::from_str(trusted_light_block.signed_header.header.chain_id.as_str())
                .unwrap()
                .revision_number();
        let trusted_block_height = trusted_light_block.height().value();
        Header {
            signed_header: self.signed_header,
            validator_set: self.validators,
            trusted_height: IbcHeight::new(trusted_revision_number, trusted_block_height).unwrap(),
            trusted_next_validator_set: trusted_light_block.next_validators.clone(),
        }
    }

    fn chain_id(&self) -> Result<ChainId, IdentifierError> {
        ChainId::from_str(self.signed_header.header.chain_id.as_str())
    }
}
