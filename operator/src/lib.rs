use alloy_sol_types::SolValue;
use ibc_client_tendermint::types::Header;
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::ConsensusState;
use sp1_ics07_tendermint_shared::types::sp1_ics07_tendermint::Env;
use sp1_sdk::{ProverClient, SP1PlonkBn254Proof, SP1ProvingKey, SP1Stdin, SP1VerifyingKey};

mod types;
pub mod util;

/// A prover for for [`SP1ICS07TendermintProgram`] programs.
pub struct SP1ICS07TendermintProver<T: SP1ICS07TendermintProgram> {
    pub prover_client: ProverClient,
    pub pkey: SP1ProvingKey,
    pub vkey: SP1VerifyingKey,
    _phantom: std::marker::PhantomData<T>,
}

/// Trait for SP1 ICS07 Tendermint programs.
pub trait SP1ICS07TendermintProgram {
    const ELF: &'static [u8];
}

/// SP1 ICS07 Tendermint update client program.
pub struct UpdateClientProgram;
impl SP1ICS07TendermintProgram for UpdateClientProgram {
    const ELF: &'static [u8] =
        include_bytes!("../../elf/update-client-riscv32im-succinct-zkvm-elf");
}

/// SP1 ICS07 Tendermint verify membership program.
pub struct VerifyMembershipProgram;
impl SP1ICS07TendermintProgram for VerifyMembershipProgram {
    const ELF: &'static [u8] =
        include_bytes!("../../elf/verify-membership-riscv32im-succinct-zkvm-elf");
}

impl<T: SP1ICS07TendermintProgram> Default for SP1ICS07TendermintProver<T> {
    fn default() -> Self {
        Self::new()
    }
}

impl<T: SP1ICS07TendermintProgram> SP1ICS07TendermintProver<T> {
    pub fn new() -> Self {
        log::info!("Initializing SP1 ProverClient...");
        let prover_client = ProverClient::new();
        let (pkey, vkey) = prover_client.setup(T::ELF);
        log::info!("SP1 ProverClient initialized");
        Self {
            prover_client,
            pkey,
            vkey,
            _phantom: std::marker::PhantomData,
        }
    }
}

impl SP1ICS07TendermintProver<UpdateClientProgram> {
    /// Generate a proof of an update from trusted_consensus_state to a proposed header.
    pub fn generate_proof(
        &self,
        trusted_consensus_state: &ConsensusState,
        proposed_header: &Header,
        contract_env: &Env,
    ) -> SP1PlonkBn254Proof {
        // Encode the light blocks to be input into our program.
        let encoded_1 = trusted_consensus_state.abi_encode();
        let encoded_2 = serde_cbor::to_vec(proposed_header).unwrap();
        let encoded_3 = serde_cbor::to_vec(contract_env).unwrap();

        // Write the encoded light blocks to stdin.
        let mut stdin = SP1Stdin::new();
        stdin.write_vec(encoded_1);
        stdin.write_vec(encoded_2);
        stdin.write_vec(encoded_3);

        // Generate the proof. Depending on SP1_PROVER env variable, this may be a mock, local or network proof.
        let proof = self
            .prover_client
            .prove_plonk(&self.pkey, stdin)
            .expect("proving failed");

        // Verify proof.
        self.prover_client
            .verify_plonk(&proof, &self.vkey)
            .expect("Verification failed");

        // Return the proof.
        proof
    }
}

impl SP1ICS07TendermintProver<VerifyMembershipProgram> {
    /// Generate a proof of a verify membership from trusted_consensus_state to a proposed header.
    pub fn generate_proof(&self, _root: &[u8], _path: &str) -> SP1PlonkBn254Proof {
        todo!();
    }
}
