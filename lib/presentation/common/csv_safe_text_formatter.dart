import 'package:flutter/services.dart';

/// Strips double quotes and line breaks as they are typed or pasted. Every
/// CSV field this app exports is quoted, so an embedded quote mark would need
/// escaping and a line break would span physical lines; keeping both out of
/// free text at entry time means a fresh row never needs either.
final csvSafeTextFormatter = FilteringTextInputFormatter.deny(
  RegExp(r'["\r\n]'),
);
