import 'package:flutter/services.dart';

/// Kurdish and Arabic keyboards type ٠١٢٣ or ۰۱۲۳ instead of 0123.
/// These helpers turn them into normal digits so numbers are read correctly.
class Digits {
  static const _eastern = '٠١٢٣٤٥٦٧٨٩';
  static const _persian = '۰۱۲۳۴۵۶۷۸۹';

  static String toWestern(String input) {
    final out = StringBuffer();
    for (final ch in input.split('')) {
      final e = _eastern.indexOf(ch);
      final p = _persian.indexOf(ch);
      out.write(e >= 0 ? '$e' : (p >= 0 ? '$p' : ch));
    }
    return out.toString();
  }

  /// "١٥,٠٠٠ IQD" -> 15000. Returns null if there are no digits.
  static int? parse(String input) {
    final digits = toWestern(input).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || digits.length > 12) return null;
    return int.tryParse(digits);
  }

  /// Keeps only digits in a text field, converting Kurdish/Arabic ones.
  static final TextInputFormatter onlyDigits = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = toWestern(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });
}
