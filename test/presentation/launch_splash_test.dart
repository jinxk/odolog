import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/presentation/splash/launch_splash.dart';

void main() {
  Finder gauge() => find.descendant(
    of: find.byType(LaunchSplash),
    matching: find.byType(CustomPaint),
  );

  testWidgets('covers the app with the gauge, then reveals it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LaunchSplash(child: Text('home'))),
    );

    expect(gauge(), findsOneWidget);

    // Mid sweep the overlay is still up.
    await tester.pump(const Duration(milliseconds: 400));
    expect(gauge(), findsOneWidget);

    // Past the full timeline the overlay is gone and only the app remains.
    await tester.pumpAndSettle();
    expect(gauge(), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('does not replay when the tree rebuilds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LaunchSplash(child: Text('home'))),
    );
    await tester.pumpAndSettle();
    expect(gauge(), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: LaunchSplash(child: Text('home'))),
    );
    await tester.pump();
    expect(gauge(), findsNothing);
  });

  testWidgets('skips straight to the app when animations are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LaunchSplash(child: Text('home')),
        ),
      ),
    );

    expect(gauge(), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
