import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zankoswap/core/theme/app_theme.dart';
import 'package:zankoswap/features/legal/privacy_policy_content.dart';
import 'package:zankoswap/features/legal/privacy_policy_screen.dart';

Widget _wrap(Widget child) => AppThemeScope(
  palette: AppPalette.emerald,
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('shows Kurdish first, switches language, and records consent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var accepted = false;
    Locale? chosen;

    await tester.pumpWidget(
      _wrap(
        PrivacyPolicyScreen(
          locale: const Locale('ku'),
          onLocaleChanged: (l) => chosen = l,
          onAccepted: () => accepted = true,
        ),
      ),
    );

    expect(find.text(PrivacyPolicyText.kurdish.title), findsOneWidget);
    expect(find.text(PrivacyPolicyText.kurdish.agree), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyPolicyText.arabic.title), findsOneWidget);
    expect(chosen, const Locale('ar'));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyPolicyText.english.title), findsOneWidget);

    await tester.tap(find.text(PrivacyPolicyText.english.agree));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
    expect(await PrivacyPolicyScreen.isAccepted(), isTrue);
  });

  testWidgets('read-only mode from settings has no agree button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PrivacyPolicyScreen(locale: Locale('en'))),
    );
    expect(find.text(PrivacyPolicyText.english.agree), findsNothing);
  });

  test('every language has the same sections', () {
    expect(
      PrivacyPolicyText.arabic.sections.length,
      PrivacyPolicyText.kurdish.sections.length,
    );
    expect(
      PrivacyPolicyText.english.sections.length,
      PrivacyPolicyText.kurdish.sections.length,
    );
  });
}
