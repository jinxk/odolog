import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/presentation/common/error_view.dart';

Future<int> pumpView(
  WidgetTester tester,
  Object error, {
  bool compact = false,
}) async {
  var retries = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ErrorView(
          error: error,
          compact: compact,
          onRetry: () => retries++,
        ),
      ),
    ),
  );
  return retries;
}

void main() {
  testWidgets('a failure shows its own message', (tester) async {
    await pumpView(tester, const DatabaseFailure('Could not read the log.'));

    expect(find.text('Could not read the log.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('anything else shows a plain line, not the exception', (
    tester,
  ) async {
    await pumpView(tester, Exception('SqliteException 11: disk image'));

    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.textContaining('SqliteException'), findsNothing);
  });

  testWidgets('Retry calls back', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: const NotFoundFailure('Gone.'),
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('the compact variant keeps the message and the retry', (
    tester,
  ) async {
    await pumpView(
      tester,
      const DatabaseFailure('Could not read the log.'),
      compact: true,
    );

    expect(find.text('Could not read the log.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
