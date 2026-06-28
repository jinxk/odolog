import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/value_objects/window_mileage.dart';
import 'package:odolog/presentation/common/mileage_trend.dart';
import 'package:odolog/presentation/common/stat_card.dart';

WindowMileage _window(double mileage) => WindowMileage(
  openingEntryId: 1,
  closingEntryId: 2,
  distance: 600,
  fuelConsumed: 30,
  mileage: mileage,
  costInWindow: 3000,
  costPerKm: 5,
);

void main() {
  testWidgets(
    'the mileage trend chart carries a spoken summary of its figures',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MileageTrend(
              windows: [_window(22), _window(18)],
              unit: 'km/kg',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Mileage trend, latest 18.0 km/kg, best 22.0 km/kg',
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('a stat tile reads its label and value as one utterance', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatTile(label: 'Quantity', value: '30.00 L'),
        ),
      ),
    );

    final data = tester.getSemantics(find.byType(StatTile));
    expect(data.label, contains('Quantity'));
    expect(data.label, contains('30.00 L'));
    handle.dispose();
  });
}
