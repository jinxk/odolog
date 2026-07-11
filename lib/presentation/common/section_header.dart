import 'package:flutter/material.dart';

/// A sentence-case label that heads a group of cards or rows.
///
/// Set in the section-title slot at semibold weight rather than uppercased:
/// hierarchy on a screen comes from the jump between the large title, this, and
/// the body, so casing does not have to do that work. Uppercase is rationed to
/// at most one element per screen.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}
