//! Contains the command line interface for the application.

use clap::{command, Parser};

/// The command line interface for the operator.
#[derive(Clone, Debug, Parser)]
#[command(author, version, about, long_about = None)]
pub struct OperatorCli {
    /// The subcommand to run.
    #[command(subcommand)]
    pub command: Commands,
}

/// The subcommands for the operator.
#[derive(Clone, Debug, Parser)]
pub enum Commands {
    /// The subcommand to run the operator.
    Start(operator::Args),
    /// The subcommand to produce the `genesis.json` file.
    Genesis(genesis::Args),
    /// The subcommand to produce the fixtures for testing.
    Fixtures(fixtures::Cmd),
}

/// The cli interface for the genesis command.
pub mod genesis {
    use super::Parser;

    /// The arguments for the `genesis` executable.
    #[derive(Parser, Debug, Clone)]
    pub struct Args {
        /// Trusted block.
        #[clap(long)]
        pub trusted_block: Option<u32>,
        /// Genesis path.
        #[clap(long, default_value = "../contracts/script")]
        pub genesis_path: String,
    }
}

/// The cli interface for the operator.
pub mod operator {
    use super::Parser;
    /// Command line arguments for the operator.
    #[derive(Parser, Debug, Clone)]
    pub struct Args {
        /// Run update-client only once and then exit.
        #[clap(long)]
        pub only_once: bool,
    }
}

/// The cli interface for the fixtures.
pub mod fixtures {
    use super::{command, Parser};

    /// The cli interface for the fixtures.
    #[derive(Clone, Debug, Parser)]
    #[command(about = "Generate fixtures for SP1ICS07Tendermint contract")]
    pub struct Cmd {
        /// The subcommand to run.
        #[command(subcommand)]
        pub command: Cmds,
    }

    /// The subcommands for the fixtures.
    #[derive(Clone, Debug, Parser)]
    pub enum Cmds {
        /// The subcommand to generate the update client fixtures.
        UpdateClient(UpdateClientCmd),
        /// The subcommand to generate the verify membership fixtures.
        VerifyMembership(VerifyMembershipCmd),
    }

    /// The arguments for the `UpdateClient` fixture executable.
    #[derive(Parser, Debug, Clone)]
    #[command(about = "Generate the update client fixture")]
    pub struct UpdateClientCmd {
        /// Trusted block.
        #[clap(long)]
        pub trusted_block: u32,

        /// Target block.
        #[clap(long, env)]
        pub target_block: u32,

        /// Fixture path.
        #[clap(long, short = 'o')]
        pub output_path: String,
    }

    /// The arguments for the `VerifyMembership` fixture executable.
    #[derive(Parser, Debug, Clone)]
    #[command(about = "Generate the verify (non)membership fixture")]
    pub struct VerifyMembershipCmd {
        /// Trusted block.
        #[clap(long)]
        pub trusted_block: u32,

        /// Key path to prove membership.
        // TODO: Add default value.
        #[clap(long)]
        pub key_path: String,

        /// Fixture path.
        #[clap(long, short = 'o')]
        pub output_path: String,
    }
}
