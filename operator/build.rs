use sp1_helper::{build_program_with_args, BuildArgs};

// Build script to build the programs if they change.
fn main() {
    // Build the update-client program.
    build_program_with_args(
        "../programs/update-client",
        BuildArgs {
            elf_name: "update-client-riscv32im-succinct-zkvm-elf".to_string(),
            ..Default::default()
        },
    );

    // Build the membership program.
    build_program_with_args(
        "../programs/membership",
        BuildArgs {
            elf_name: "membership-riscv32im-succinct-zkvm-elf".to_string(),
            ..Default::default()
        },
    );

    // Build the uc-and-membership program.
    build_program_with_args(
        "../programs/uc-and-membership",
        BuildArgs {
            elf_name: "uc-and-membership-riscv32im-succinct-zkvm-elf".to_string(),
            ..Default::default()
        },
    );
}
