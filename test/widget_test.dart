import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zankoswap/app/app.dart';

void main() {
  testWidgets('ZankoSwap app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZankoSwapApp());
    await tester.pump();

    expect(find.byType(ZankoSwapApp), findsOneWidget);
  });
}
