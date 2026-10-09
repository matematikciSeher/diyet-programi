import 'dart:io';

import 'package:diyet_programi/core/config/app_config.dart';
import 'package:diyet_programi/core/config/app_environment.dart';
import 'package:diyet_programi/core/legal/privacy_policy_link.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:diyet_programi/core/routing/app_routes.dart';
import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/profile/presentation/pages/profile_page.dart';
import 'package:diyet_programi/features/settings/presentation/pages/settings_page.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AppConfig _config(String url) => AppConfig(
  environment: AppEnvironment.prod,
  appName: 'Diyet Programı',
  apiBaseUrl: '',
  aiProxyBaseUrl: '',
  foodApiBaseUrl: '',
  revenueCatApiKeyIos: '',
  revenueCatApiKeyAndroid: '',
  enableAnalytics: true,
  enableCrashReporting: true,
  useFakeServices: false,
  privacyPolicyUrl: url,
);

void main() {
  const policyUrl =
      'https://matematikciSeher.github.io/diyet-programi/privacy-policy.html';

  tearDown(() => PrivacyPolicyLink.debugLaunch = null);

  test('geçerli gizlilik adresi config üzerinden okunur', () {
    final config = _config(policyUrl);
    expect(config.isPrivacyPolicyUrlConfigured, isTrue);
    expect(config.privacyPolicyUri, Uri.parse(policyUrl));
  });

  test('boş, örnek ve geçersiz adres açılmaz', () async {
    for (final url in ['', '   ', 'https://privacy.example.com/policy', 'not a url', 'ftp://files.local/policy']) {
      final config = _config(url);
      expect(config.privacyPolicyUri, isNull, reason: url);
      var launched = false;
      PrivacyPolicyLink.debugLaunch = (_) async {
        launched = true;
        return true;
      };
      expect(await PrivacyPolicyLink.open(config), isFalse);
      expect(launched, isFalse);
    }
  });

  test('ayarlanmış adres dış bağlantıya verilir', () async {
    Uri? opened;
    PrivacyPolicyLink.debugLaunch = (uri) async {
      opened = uri;
      return true;
    };
    expect(await PrivacyPolicyLink.open(_config(policyUrl)), isTrue);
    expect(opened, Uri.parse(policyUrl));
  });

  test('iletişim e-postası boş veya örnekse yayınlanmaz', () {
    expect(_config(policyUrl).isPrivacyContactEmailConfigured, isFalse);
    expect(
      const AppConfig(
        environment: AppEnvironment.prod,
        appName: 'Diyet Programı',
        apiBaseUrl: '',
        aiProxyBaseUrl: '',
        foodApiBaseUrl: '',
        revenueCatApiKeyIos: '',
        revenueCatApiKeyAndroid: '',
        enableAnalytics: true,
        enableCrashReporting: true,
        useFakeServices: false,
        privacyPolicyUrl: policyUrl,
        privacyContactEmail: 'privacy@example.com',
      ).isPrivacyContactEmailConfigured,
      isFalse,
    );
  });

  test('gerçek iletişim e-postası config’te kabul edilir', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      appName: 'Diyet Programı',
      apiBaseUrl: '',
      aiProxyBaseUrl: '',
      foodApiBaseUrl: '',
      foodApiContactEmail: 'seheraydin42@gmail.com',
      revenueCatApiKeyIos: '',
      revenueCatApiKeyAndroid: '',
      enableAnalytics: true,
      enableCrashReporting: true,
      useFakeServices: false,
      privacyPolicyUrl: policyUrl,
      privacyContactEmail: 'seheraydin42@gmail.com',
    );
    expect(config.isPrivacyContactEmailConfigured, isTrue);
    expect(
      FoodApiConfig.userAgentFor(contactEmail: config.foodApiContactEmail),
      'DiyetProgrami/1.0.0 (seheraydin42@gmail.com)',
    );
  });

  test('gizlilik metni kod davranışıyla çelişen iddia içermez', () {
    final html = File('privacy-policy.html').readAsStringSync();
    final docs = File('docs/privacy-policy.html').readAsStringSync();
    expect(docs, html);
    expect(html.contains('seheraydin42@gmail.com'), isTrue);
    expect(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
          .allMatches(html)
          .map((match) => match.group(0))
          .toSet(),
      {'seheraydin42@gmail.com'},
    );
    for (final claim in [
      'Sağlık verileri cihazdan hiç çıkmaz',
      'Fotoğraflar hiçbir zaman sunucuya gönderilmez',
      'Hiçbir veri üçüncü taraflarla paylaşılmaz',
    ]) {
      expect(html.contains(claim), isFalse, reason: claim);
    }
    for (final topic in [
      'Firebase Authentication',
      'Firestore',
      'Analytics',
      'Crashlytics',
      'Health Connect',
      'HealthKit',
      'Open Food Facts',
      'speech_to_text',
      'yapay zeka proxy',
      'onboarding taslağı',
      'hesap sil',
    ]) {
      expect(html.toLowerCase().contains(topic.toLowerCase()), isTrue, reason: topic);
    }
  });

  testWidgets('Profil ayarlardan gizlilik politikasını config adresiyle açar', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    Uri? opened;
    PrivacyPolicyLink.debugLaunch = (uri) async {
      opened = uri;
      return true;
    };
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const SettingsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_config(policyUrl)),
          keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final settingsTile = find.text(l10n.featureSettings);
    await tester.ensureVisible(settingsTile);
    await tester.pumpAndSettle();
    await tester.tap(settingsTile);
    await tester.pumpAndSettle();
    final policyTile = find.text(l10n.settingsPrivacyPolicy);
    await tester.ensureVisible(policyTile);
    await tester.pumpAndSettle();
    expect(policyTile, findsOneWidget);
    await tester.tap(policyTile);
    await tester.pumpAndSettle();
    expect(opened, Uri.parse(policyUrl));
    expect(find.text(l10n.settingsPrivacyPolicyUnavailable), findsNothing);
  });

  testWidgets('boş adres Ayarlar’da güvenli uyarı gösterir', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_config('')),
          keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final policyTile = find.text(l10n.settingsPrivacyPolicy);
    await tester.ensureVisible(policyTile);
    await tester.pumpAndSettle();
    await tester.tap(policyTile);
    await tester.pump();
    expect(find.text(l10n.settingsPrivacyPolicyUnavailable), findsOneWidget);
  });
}
