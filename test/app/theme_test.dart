import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/app/theme/theme.dart';

void main() {
  // A button style's textStyle replaces the theme's font instead of merging
  // with it, so the label fell back to the system font on phones.
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('filled button label uses Inter in the $name theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FilledButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      );

      final label = tester.widget<RichText>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(RichText),
        ),
      );
      expect(label.text.style?.fontFamily, 'Inter');
      expect(label.text.style?.fontSize, 16);
      expect(label.text.style?.fontWeight, FontWeight.w700);
    });
  }
}
