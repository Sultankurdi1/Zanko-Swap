import 'package:flutter_test/flutter_test.dart';
import 'package:zankoswap/core/data/search_text.dart';

void main() {
  test('Arabic keyboard letters find Kurdish words', () {
    expect(SearchText.matches('كتيب', ['کتێبی بیرکاری']), isTrue);
    expect(SearchText.matches('کتیب', ['کتێب']), isTrue);
    expect(SearchText.matches('كوليژ', ['کۆلێژی پزیشکی']), isTrue);
    expect(SearchText.matches('ملزمه', ['ملزمەی فیزیا']), isTrue);
  });

  test('every word must appear, in any order', () {
    expect(SearchText.matches('فیزیا ملزمە', ['ملزمەی فیزیا']), isTrue);
    expect(SearchText.matches('فیزیا کیمیا', ['ملزمەی فیزیا']), isFalse);
  });

  test('digits, case, marks and invisible characters are ignored', () {
    expect(SearchText.matches('٢٠٢٦', ['Exam 2026']), isTrue);
    expect(SearchText.matches('MATH', ['math book']), isTrue);
    expect(SearchText.matches('كِتاب', ['کتاب']), isTrue);
    expect(SearchText.matches('کتێب', ['کت‌ێب']), isTrue);
  });

  test('empty query matches everything, unknown text does not', () {
    expect(SearchText.matches('  ', ['anything']), isTrue);
    expect(SearchText.matches('laptop', ['کتێب', null]), isFalse);
  });
}
