/// Pure estimate of how much fuel a top-up fill needs to bring the tank back
/// to full. No Flutter, no database, like the other calculators.
class TopUpEstimator {
  const TopUpEstimator();

  /// A real tank holds more than its nominal capacity, so the warning starts
  /// this fraction above it.
  static const warningMarginFraction = 0.1;

  /// True once [quantity] exceeds [tankCapacity] by more than
  /// [warningMarginFraction]. At the nominal capacity, or anywhere within the
  /// margin above it, this is false.
  bool exceedsCapacity(double quantity, double tankCapacity) =>
      quantity > tankCapacity * (1 + warningMarginFraction);

  /// The fuel burned since the last full fill, capped at [tankCapacity] and
  /// rounded to one decimal. Falls back to [tankCapacity] itself when
  /// [distanceSinceLastFullFill] or [averageMileage] is unknown or not
  /// positive.
  double estimate({
    required double tankCapacity,
    required double? distanceSinceLastFullFill,
    required double? averageMileage,
  }) {
    if (distanceSinceLastFullFill == null ||
        averageMileage == null ||
        distanceSinceLastFullFill <= 0 ||
        averageMileage <= 0) {
      return _round(tankCapacity);
    }
    final fuelUsed = distanceSinceLastFullFill / averageMileage;
    return _round(fuelUsed < tankCapacity ? fuelUsed : tankCapacity);
  }

  double _round(double value) => double.parse(value.toStringAsFixed(1));
}
