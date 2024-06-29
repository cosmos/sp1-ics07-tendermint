use core::str::FromStr;
use std::{collections::HashMap, env};

use anyhow::Result;

use tendermint::{block::signed_header::SignedHeader, validator::Set};
use tendermint_light_client_verifier::types::{LightBlock, ValidatorSet};
use tendermint_rpc::{Client, HttpClient, Paging, Url};

pub struct TendermintRPCClient(HttpClient);

impl Default for TendermintRPCClient {
    fn default() -> Self {
        Self::new()
    }
}

impl TendermintRPCClient {
    pub fn new() -> Self {
        Self(
            HttpClient::new::<Url>(
                Url::from_str(&env::var("TENDERMINT_RPC_URL").expect("TENDERMINT_RPC_URL not set"))
                    .expect("Failed to parse URL"),
            )
            .expect("Failed to create HTTP client"),
        )
    }

    /// Get the inner tendermint [`HttpClient`].
    pub fn as_tm_client(&self) -> &HttpClient {
        &self.0
    }

    /// Gets a light block for a specific block height and peer ID.
    pub async fn get_light_block(&self, block_height: Option<u32>) -> Result<LightBlock> {
        let peer_id = self.as_tm_client().status().await?.node_info.id;
        let commit_response;
        let height;
        if let Some(block_height) = block_height {
            commit_response = self.as_tm_client().commit(block_height).await?;
            height = block_height;
        } else {
            commit_response = self.as_tm_client().latest_commit().await?;
            height = commit_response.signed_header.header.height.value() as u32;
        }
        let mut signed_header = commit_response.signed_header;

        let validator_response = self.as_tm_client().validators(height, Paging::All).await?;

        let validators = Set::new(validator_response.validators, None);

        let next_validator_response = self
            .as_tm_client()
            .validators(height + 1, Paging::All)
            .await?;
        let next_validators = Set::new(next_validator_response.validators, None);

        sort_signatures_by_validators_power_desc(&mut signed_header, &validators);
        Ok(LightBlock::new(
            signed_header,
            validators,
            next_validators,
            peer_id,
        ))
    }
}

/// Sorts the signatures in the signed header based on the descending order of validators' power.
fn sort_signatures_by_validators_power_desc(
    signed_header: &mut SignedHeader,
    validators_set: &ValidatorSet,
) {
    let validator_powers: HashMap<_, _> = validators_set
        .validators()
        .iter()
        .map(|v| (v.address, v.power()))
        .collect();

    signed_header.commit.signatures.sort_by(|a, b| {
        let power_a = a
            .validator_address()
            .and_then(|addr| validator_powers.get(&addr))
            .unwrap_or(&0);
        let power_b = b
            .validator_address()
            .and_then(|addr| validator_powers.get(&addr))
            .unwrap_or(&0);
        power_b.cmp(power_a)
    });
}
