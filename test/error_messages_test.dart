import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zankoswap/core/localization/app_strings.dart';

void main() {
  final s = AppStrings(const Locale('ku'));

  test('blocked words show the inappropriate text message', () {
    final error = Exception(
      'PostgrestException(message: inappropriate_content, code: P0001)',
    );
    expect(s.errorFor(error), s.inappropriateContent);
  });

  test('rejected photos show the inappropriate image message', () {
    final error = Exception(
      'FunctionException(status: 422, details: {error: inappropriate_image})',
    );
    expect(s.errorFor(error), s.inappropriateImage);
  });

  test('image check outage asks to try later', () {
    final error = Exception(
      'FunctionException(status: 503, details: {error: moderation_unavailable})',
    );
    expect(s.errorFor(error), s.imageCheckUnavailable);
  });

  test('anything else stays generic and hides technical details', () {
    final error = Exception('SocketException: Failed host lookup');
    expect(s.errorFor(error), s.genericError);
  });
}
