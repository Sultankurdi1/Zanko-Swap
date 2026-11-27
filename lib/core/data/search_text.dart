import 'digits.dart';

/// Search that works the same whether people type with a Kurdish, Arabic or
/// Persian keyboard: "كتێب", "کتیب" and "كتيب" all find "کتێب".
class SearchText {
  const SearchText._();

  // Letters folded to one form. Arabic keyboards have no ێ ۆ ڕ ڵ ڤ پ چ ژ گ,
  // so people type the nearest Arabic letter instead.
  static const _fold = {
    'ك': 'ک', 'گ': 'ک', //
    'ي': 'ی', 'ى': 'ی', 'ێ': 'ی', 'ې': 'ی', //
    'ە': 'ه', 'ة': 'ه', 'ھ': 'ه', 'ۀ': 'ه', 'ہ': 'ه', //
    'ۆ': 'و', 'ؤ': 'و', 'ۇ': 'و', //
    'ڕ': 'ر', 'ڵ': 'ل', 'ڤ': 'ف', //
    'پ': 'ب', 'چ': 'ج', 'ژ': 'ز', //
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ئ': 'ا', 'ء': '',
  };

  // Vowel marks, tatweel and invisible direction/joiner characters.
  static final _ignored = RegExp(
    '[\\u064B-\\u065F\\u0670\\u0640\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069\\uFEFF]',
  );
  static final _spaces = RegExp(r'\s+');

  static String normalize(String input) {
    final cleaned = Digits.toWestern(
      input.toLowerCase(),
    ).replaceAll(_ignored, '');
    final out = StringBuffer();
    for (final rune in cleaned.runes) {
      final ch = String.fromCharCode(rune);
      out.write(_fold[ch] ?? ch);
    }
    return out.toString().replaceAll(_spaces, ' ').trim();
  }

  /// True when every word of [query] appears in at least one of [fields],
  /// in any order. An empty query matches everything.
  static bool matches(String query, Iterable<String?> fields) {
    final words = normalize(query).split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final haystack = normalize(fields.whereType<String>().join(' '));
    return words.every(haystack.contains);
  }
}
