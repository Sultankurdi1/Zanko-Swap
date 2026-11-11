import 'package:flutter_test/flutter_test.dart';
import 'package:zankoswap/core/data/digits.dart';
import 'package:zankoswap/features/legal/age_gate.dart';

void main() {
  test('prices typed on Kurdish and Arabic keyboards are read', () {
    expect(Digits.parse('15000'), 15000);
    expect(Digits.parse('١٥٠٠٠'), 15000);
    expect(Digits.parse('۱۵,۰۰۰ IQD'), 15000);
    expect(Digits.parse(''), isNull);
    expect(Digits.parse('abc'), isNull);
  });

  test('age is counted to the exact birthday', () {
    final today = DateTime(2026, 11, 12);
    expect(AgeGate.ageOn(DateTime(2013, 11, 12), today), 13);
    expect(AgeGate.ageOn(DateTime(2013, 11, 13), today), 12);
    expect(AgeGate.ageOn(DateTime(2000, 1, 1), today), 26);
  });
}
