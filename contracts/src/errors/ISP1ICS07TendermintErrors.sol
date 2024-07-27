// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

interface ISP1ICS07TendermintErrors {
    /// @notice The error that is returned when the verification key does not match the expected value.
    /// @param expected The expected verification key.
    /// @param actual The actual verification key.
    error VerificationKeyMismatch(bytes32 expected, bytes32 actual);

    /// @notice The error that is returned when the client state is frozen.
    error FrozenClientState();

    /// @notice The error that is returned when a proof is in the future.
    /// @param now The current timestamp in seconds.
    /// @param proofTimestamp The timestamp in the proof in seconds.
    error ProofIsInTheFuture(uint256 now, uint256 proofTimestamp);

    /// @notice The error that is returned when a proof is too old.
    /// @param now The current timestamp in seconds.
    /// @param proofTimestamp The timestamp in the proof in seconds.
    error ProofIsTooOld(uint256 now, uint256 proofTimestamp);

    /// @notice The error that is returned when the chain ID does not match the expected value.
    /// @param expected The expected chain ID.
    /// @param actual The actual chain ID.
    error ChainIdMismatch(string expected, string actual);

    /// @notice The error that is returned when the trust threshold does not match the expected value.
    /// @param expectedNumerator The expected numerator of the trust threshold.
    /// @param expectedDenominator The expected denominator of the trust threshold.
    /// @param actualNumerator The actual numerator of the trust threshold.
    /// @param actualDenominator The actual denominator of the trust threshold.
    error TrustThresholdMismatch(
        uint256 expectedNumerator, uint256 expectedDenominator, uint256 actualNumerator, uint256 actualDenominator
    );

    /// @notice The error that is returned when the trusting period does not match the expected value.
    /// @param expected The expected trusting period in seconds.
    /// @param actual The actual trusting period in seconds.
    error TrustingPeriodMismatch(uint256 expected, uint256 actual);

    /// @notice The error that is returned when the trusting period is longer than the unbonding period.
    /// @param trustingPeriod The trusting period in seconds.
    /// @param unbondingPeriod The unbonding period in seconds.
    error TrustingPeriodTooLong(uint256 trustingPeriod, uint256 unbondingPeriod);

    /// @notice The error that is returned when the consensus state hash does not match the expected value.
    /// @param expected The expected consensus state hash.
    /// @param actual The actual consensus state hash.
    error ConsensusStateHashMismatch(bytes32 expected, bytes32 actual);

    /// @notice The error that is returned when the consensus state is not found.
    error ConsensusStateNotFound();
}
