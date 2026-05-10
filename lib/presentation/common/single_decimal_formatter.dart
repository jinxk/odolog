import 'package:flutter/services.dart';

/// A single decimal point, digits only formatter for numeric fields.
///
/// A plain `[0-9.]` allow-filter still lets a value like "3.4.5" through, which
/// then fails to parse only at Save; rejecting the whole edit whenever it would
/// produce a second decimal point makes that input impossible to type instead
/// of deferring the error. Shared by the refuel form's amount fields and the
/// vehicle form's claimed mileage field so they behave identically.
class SingleDecimalFormatter extends TextInputFormatter {
  static final _validPartial = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (!_validPartial.hasMatch(newValue.text)) return oldValue;
    return newValue;
  }
}
