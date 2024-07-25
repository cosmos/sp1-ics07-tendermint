//! Contains the command line interface for the application.

use clap::{command, Parser};
use tendermint_light_client_verifier::types::TrustThreshold;

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
        /// Trusted block height. [default: latest]
        #[clap(long)]
        pub trusted_block: Option<u32>,
        /// Genesis path.
        #[clap(long, default_value = "../contracts/script")]
        pub genesis_path: String,
        /// Trust level.
        #[clap(
            long,
            default_value = "1/3",
            value_parser = super::parse_trust_threshold,
            help = "Trust level as a fraction, e.g. '2/3'",
        )]
        pub trust_level: super::TrustThreshold,
        /// Trusting period. [default: 2/3 of unbonding period]
        #[clap(long)]
        pub trusting_period: Option<u32>,
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
        /// The subcommand to generate the verify (non)membership fixtures.
        Membership(MembershipCmd),
        /// The subcommand to generate the update client and verify (non)membership fixtures.
        UpdateClientAndMembership(UpdateClientAndMembershipCmd),
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

        /// Trust level.
        #[clap(
            long,
            default_value = "1/3",
            value_parser = super::parse_trust_threshold,
            help = "Trust level as a fraction, e.g. '2/3'",
        )]
        pub trust_level: super::TrustThreshold,

        /// Trusting period. [default: 2/3 of unbonding period]
        #[clap(long)]
        pub trusting_period: Option<u32>,
    }

    /// The arguments for the `Membership` fixture executable.
    #[derive(Parser, Debug, Clone)]
    #[command(about = "Generate the verify (non)membership fixture")]
    pub struct MembershipCmd {
        /// Trusted block.
        #[clap(long)]
        pub trusted_block: u32,

        /// Key paths to prove membership.
        #[clap(long, value_delimiter = ',')]
        pub key_paths: Vec<String>,

        /// Fixture path.
        #[clap(long, short = 'o')]
        pub output_path: String,

        /// Trust level.
        #[clap(
            long,
            default_value = "1/3",
            value_parser = super::parse_trust_threshold,
            help = "Trust level as a fraction, e.g. '2/3'",
        )]
        pub trust_level: super::TrustThreshold,

        /// Trusting period. [default: 2/3 of unbonding period]
        #[clap(long)]
        pub trusting_period: Option<u32>,
    }

    /// The arguments for the `UpdateClientAndMembership` fixture executable.
    #[derive(Parser, Debug, Clone)]
    #[command(about = "Generate the update client and membership fixture")]
    pub struct UpdateClientAndMembershipCmd {
        /// Trusted block.
        #[clap(long)]
        pub trusted_block: u32,

        /// Target block.
        #[clap(long, env)]
        pub target_block: u32,

        /// Key paths to prove membership.
        #[clap(long, value_delimiter = ',')]
        pub key_paths: Vec<String>,

        /// Fixture path.
        #[clap(long, short = 'o')]
        pub output_path: String,

        /// Trust level.
        #[clap(
            long,
            default_value = "1/3",
            value_parser = super::parse_trust_threshold,
            help = "Trust level as a fraction, e.g. '2/3'",
        )]
        pub trust_level: super::TrustThreshold,

        /// Trusting period. [default: 2/3 of unbonding period]
        #[clap(long)]
        pub trusting_period: Option<u32>,
    }
}

fn parse_trust_threshold(input: &str) -> anyhow::Result<TrustThreshold> {
    let (num_part, denom_part) = input.split_once('/').ok_or_else(|| {
        anyhow::anyhow!("invalid trust threshold fraction: expected format 'numerator/denominator'")
    })?;
    let numerator = num_part
        .trim()
        .parse()
        .map_err(|_| anyhow::anyhow!("invalid numerator for the fraction"))?;
    let denominator = denom_part
        .trim()
        .parse()
        .map_err(|_| anyhow::anyhow!("invalid denominator for the fraction"))?;
    TrustThreshold::new(numerator, denominator)
        .map_err(|e| anyhow::anyhow!("invalid trust threshold: {}", e))
}
