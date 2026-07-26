import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/presentation/common/formatting.dart';
import 'package:odolog/presentation/common/trend_delta_chip.dart';

void main() {
  Future<void> pumpChip(WidgetTester tester, double delta) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendDeltaChip(
            delta: delta,
            format: formatMileage,
            positiveColor: Colors.green,
            negativeColor: Colors.red,
          ),
        ),
      ),
    );
  }

  testWidgets('a rise shows a plus and an up arrow', (tester) async {
    await pumpChip(tester, 1.24);

    expect(find.text('+1.2'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('a drop shows a minus and a down arrow', (tester) async {
    await pumpChip(tester, -1.24);

    expect(find.text('-1.2'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('a drop too small to show renders no chip', (tester) async {
    await pumpChip(tester, -0.04);

    expect(find.text('-0.0'), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('an exactly flat figure renders no chip', (tester) async {
    await pumpChip(tester, 0);

    expect(find.byType(Icon), findsNothing);
  });
}
