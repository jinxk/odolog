import 'package:flutter/material.dart';

import '../../core/failures.dart';

/// A load that failed: one short line about it and the retry that runs it
/// again. Raw exceptions never reach the screen. A [Failure] carries a message
/// worth reading, anything else gets a plain line, since a stack trace tells
/// the reader nothing they can act on.
///
/// [compact] drops the icon and the centring for the places that already sit
/// inside a card or a list row, where the full centred block would shove
/// everything around it off screen.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = switch (error) {
      ValidationFailure(:final reason) => reason,
      NotFoundFailure(:final message) => message,
      DatabaseFailure(:final message) => message,
      _ => 'Something went wrong.',
    };
    if (compact) {
      return Row(
        children: [
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              text,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
