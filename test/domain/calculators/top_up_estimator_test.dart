import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/top_up_estimator.dart';

void main() {
  const estimator = TopUpEstimator();

  test('fuel used since the last full fill is capped at the tank capacity', () {
    final result = estimator.estimate(
      tankCapacity: 35,
      distanceSinceLastFullFill: 1000,
      averageMileage: 25,
    );

    expect(result, 35.0);
  });

  test('fuel used under the tank capacity rounds to one decimal', () {
    final result = estimator.estimate(
      tankCapacity: 35,
      distanceSinceLastFullFill: 100,
      averageMileage: 3,
    );

    expect(result, 33.3);
  });

  test('a clean division rounds to one decimal with no drift', () {
    final result = estimator.estimate(
      tankCapacity: 35,
      distanceSinceLastFullFill: 333,
      averageMileage: 30,
    );

    expect(result, 11.1);
  });

  test(
    'an unknown distance since the last full fill falls back to the tank capacity',
    () {
      final result = estimator.estimate(
        tankCapacity: 35,
        distanceSinceLastFullFill: null,
        averageMileage: 25,
      );

      expect(result, 35.0);
    },
  );

  test('an unknown average mileage falls back to the tank capacity', () {
    final result = estimator.estimate(
      tankCapacity: 35,
      distanceSinceLastFullFill: 500,
      averageMileage: null,
    );

    expect(result, 35.0);
  });

  test('a negative distance falls back to the tank capacity', () {
    final result = estimator.estimate(
      tankCapacity: 35,
      distanceSinceLastFullFill: -120,
      averageMileage: 25,
    );

    expect(result, 35.0);
  });

  test('a quantity at the nominal capacity does not exceed it', () {
    expect(estimator.exceedsCapacity(35, 35), isFalse);
  });

  test('a quantity at capacity plus the warning margin does not exceed it', () {
    expect(estimator.exceedsCapacity(38.5, 35), isFalse);
  });

  test('a quantity just past the warning margin exceeds it', () {
    expect(estimator.exceedsCapacity(38.6, 35), isTrue);
  });
}
