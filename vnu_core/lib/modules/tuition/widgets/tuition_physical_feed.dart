import 'dart:math' as math;

/// Small deterministic simulation of the PAPER position, not a QR generator.
/// The physical sheet is already rendered in full; only its Y position moves.
/// Fixed 120 Hz steps keep the motion reproducible across frame rates.
class TuitionPhysicalFeed {
  TuitionPhysicalFeed({required int seed}) : _random = math.Random(seed);

  final math.Random _random;
  double progress = 0;
  double elapsed = 0;
  double velocity = 0;
  double acceleration = 0;
  double noise = 1;
  double _noiseFrom = 1;
  double _noiseTo = 1;
  double _noiseStart = 0;
  double _noiseEnd = .14;
  double _nextPause = -.01;
  double _pauseLeft = 0;
  double recoil = 0;
  double _recoilVelocity = 0;
  int pauseCount = 0;

  double _ease(double t) {
    final x = t.clamp(0.0, 1.0).toDouble();
    return x * x * (3 - 2 * x);
  }

  /// `cap=.91` means the backend has not yet confirmed a new QR. Holding
  /// there never reveals an invented QR or completes the success transition.
  /// The amount fed is monotonic, regardless of spring recoil or pauses.
  void step(double dt, {
    double speed = 1.25,
    double cap = 1,
    bool boosted = false,
  }) {
    if (progress >= cap - .001) {
      progress = cap;
      velocity = 0;
      acceleration = 0;
      return;
    }
    elapsed += dt;
    if (elapsed >= _noiseEnd) {
      _noiseFrom = _noiseTo;
      _noiseTo = .70 + _random.nextDouble() * .59;
      _noiseStart = elapsed;
      _noiseEnd = elapsed + .105 + _random.nextDouble() * .19;
    }
    final blend = _ease((elapsed - _noiseStart) /
        math.max(.001, _noiseEnd - _noiseStart));
    final targetNoise = _noiseFrom + (_noiseTo - _noiseFrom) * blend;
    noise += (targetNoise - noise) * (1 - math.exp(-dt / .072));

    if (_nextPause < 0) {
      _nextPause = elapsed + .11 + _random.nextDouble() * .18;
    }
    if (elapsed >= _nextPause) {
      _nextPause = elapsed + .15 + _random.nextDouble() * .28;
      if (_random.nextDouble() < .56) {
        _pauseLeft = .018 + _random.nextDouble() * .058;
        pauseCount++;
      }
      _recoilVelocity += (_random.nextDouble() - .5) * 11;
    }

    final pausing = _pauseLeft > 0;
    _pauseLeft = math.max(0.0, _pauseLeft - dt);
    final easeToHold = cap < 1
        ? _ease((cap - progress) / .050)
        : 1.0;
    final desired = 1.90 * speed * noise * (boosted ? 2.0 : 1.0) *
        (pausing ? .025 : 1.0) * easeToHold;
    // A damped velocity spring; recoil never reverses PAPER displacement.
    acceleration += (210 * (desired - velocity) - 29 * acceleration) * dt;
    velocity = math.max(0.0, velocity + acceleration * dt);
    if (pausing) velocity *= math.exp(-20 * dt);
    progress = math.min(cap, progress + math.max(0.0, velocity) * dt);

    // Recoil affects only the printer body, not the feed distance.
    _recoilVelocity += (-360 * recoil - 38 * _recoilVelocity) * dt;
    recoil = (recoil + _recoilVelocity * dt).clamp(-.65, .65).toDouble();
  }
}
