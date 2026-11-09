import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zankoswap/features/splash/emblem_splash_screen.dart';

Future<Duration> _timeUntilFinished(WidgetTester tester) async {
  var finished = false;
  await tester.pumpWidget(
    MaterialApp(home: ZankoEmblemSplash(onFinished: () => finished = true)),
  );
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (!finished && elapsed < const Duration(seconds: 10)) {
    await tester.pump(step);
    elapsed += step;
  }
  await tester.pumpWidget(const SizedBox());
  return elapsed;
}

void main() {
  testWidgets('first launch plays the full splash, later launches are short', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final first = await _timeUntilFinished(tester);
    expect(first.inMilliseconds, closeTo(6500, 200));

    final second = await _timeUntilFinished(tester);
    expect(second.inMilliseconds, closeTo(3500, 200));
  });
}
