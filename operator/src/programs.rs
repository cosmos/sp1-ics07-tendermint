//! Programs for `sp1-ics07-tendermint`.

/// Trait for SP1 ICS07 Tendermint programs.
pub trait SP1Program {
    /// The ELF file for the program.
    const ELF: &'static [u8];
}

/// SP1 ICS07 Tendermint update client program.
pub struct UpdateClientProgram;
impl SP1Program for UpdateClientProgram {
    const ELF: &'static [u8] =
        include_bytes!("../../elf/update-client-riscv32im-succinct-zkvm-elf");
}

/// SP1 ICS07 Tendermint verify membership program.
pub struct VerifyMembershipProgram;
impl SP1Program for VerifyMembershipProgram {
    const ELF: &'static [u8] =
        include_bytes!("../../elf/verify-membership-riscv32im-succinct-zkvm-elf");
}
