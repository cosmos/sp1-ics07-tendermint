//! Contains the public value output for the sp1 program.

use super::validation::Env;
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::{ConsensusState, Height};

alloy_sol_types::sol! {
    /// The public value output for the sp1 program.
    struct SP1ICS07TendermintOutput {
        /// The trusted consensus state.
        ConsensusState trusted_consensus_state;
        /// The new consensus state with the verified header.
        ConsensusState new_consensus_state;
        /// The validation environment.
        Env env;
        /// Trusted height.
        Height trusted_height;
        /// The height of the new consensus state.
        Height new_height;
    }
}
