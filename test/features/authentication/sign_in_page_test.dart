import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:diyet_programi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _openSignIn(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(
          InMemoryKeyValueStorage({StorageKeys.onboardingCompleted: true}),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(SignInPage), findsOneWidget);
}

void main() {
  testWidgets('e-posta ile giriş dashboard açar', (tester) async {
    await _openSignIn(tester);
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.byKey(SignInPage.emailSubmitKey));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('Google ile giriş dashboard açar', (tester) async {
    await _openSignIn(tester);
    await tester.ensureVisible(find.byKey(SignInPage.googleButtonKey));
    await tester.tap(find.byKey(SignInPage.googleButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('misafir giriş dashboard açar', (tester) async {
    await _openSignIn(tester);
    await tapContinueAsGuest(tester);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('yapılandırılmamış Apple girişi iOS’ta da gizlenir', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _openSignIn(tester);
      expect(SignInPage.appleSignInAvailable, isFalse);
      expect(find.text(l10n.actionSignInWithApple), findsNothing);
      expect(find.byKey(SignInPage.googleButtonKey), findsOneWidget);
      expect(find.byKey(SignInPage.guestButtonKey), findsOneWidget);
      expect(find.byKey(SignInPage.emailSubmitKey), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('boş e-posta ile giriş ekranda kalır', (tester) async {
    await _openSignIn(tester);
    await tester.tap(find.byKey(SignInPage.emailSubmitKey));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.text(l10n.authInvalidEmail), findsOneWidget);
  });
}
