/// Tracks consecutive, recoverable PAYABLE loads that failed to supply a
/// trustworthy feed. Each failure episode may force AT MOST ONE new ULIS
/// student token. Rotating credentials cannot repair an upstream lock filter,
/// so repeated empty responses must not cause an endless token storm.
///
/// A valid, non-empty feed resets the episode. A manual re-issue deliberately
/// consumes the automatic recovery opportunity until a verified feed arrives.
class TuitionSessionRecoveryPolicy {
  TuitionSessionRecoveryPolicy({this.maxConsecutiveMisses = 3})
      : assert(maxConsecutiveMisses > 0);

  final int maxConsecutiveMisses;
  int _consecutiveMisses = 0;
  bool _rotatedInEpisode = false;

  int get consecutiveMisses => _consecutiveMisses;
  bool get rotatedInEpisode => _rotatedInEpisode;

  /// Returns true exactly once after [maxConsecutiveMisses] bad attempts.
  /// 403 ownership failures and 429 rate-limits should never call this.
  bool recordRecoverableMiss() {
    _consecutiveMisses++;
    if (_rotatedInEpisode || _consecutiveMisses < maxConsecutiveMisses) {
      return false;
    }
    _rotatedInEpisode = true;
    return true;
  }

  /// Called when the backend supplies a valid, non-empty PAYABLE snapshot.
  void recordVerifiedFeed() {
    _consecutiveMisses = 0;
    _rotatedInEpisode = false;
  }

  /// Manual refresh issued a new token; do not auto-issue another after
  /// three more temporary empty feeds unless a verified feed resets us.
  void recordManualRotation() {
    _consecutiveMisses = 0;
    _rotatedInEpisode = true;
  }
}
