import 'dart:typed_data';

import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_database_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/services/food_draft_builder.dart';
import 'package:diyet_programi/features/food/domain/services/food_image_policy.dart';
import 'package:diyet_programi/features/food/domain/services/food_vision_service.dart';
import 'package:diyet_programi/features/food/domain/services/spoken_meal_parser.dart';
import 'package:diyet_programi/features/food/domain/services/speech_input_service.dart';
import 'package:diyet_programi/features/food/presentation/pages/photo_log_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/voice_log_page.dart';
import 'package:diyet_programi/features/food/presentation/providers/estimated_food_providers.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:diyet_programi/shared/repositories/user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/media/media_permission_gateway.dart';
import 'package:diyet_programi/shared/services/media/photo_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('yapılandırılmamış fotoğraf sahte yiyecek göstermez', (tester) async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final sample = SampleFoodDatabaseService();
    final foods = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: sample,
      barcodeLookup: sample,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream<UserProfile?>.value(null)),
          mediaPermissionGatewayProvider.overrideWithValue(const _Granted()),
          foodPhotoPickerProvider.overrideWithValue(_JpegPicker()),
          foodCaptureActionsProvider.overrideWithValue(
            FoodCaptureActions(
              vision: const UnconfiguredFoodVisionService(),
              foods: foods,
              builder: const FoodDraftBuilder(),
              parser: const SpokenMealParser(),
              policy: const FoodImagePolicy(
                maxBytes: 1500000,
                maxDimension: 1280,
                jpegQuality: 80,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const PhotoLogPage(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('photo-camera')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.captureErrorNotConfigured), findsOneWidget);
    expect(find.text('Haşlanmış yumurta'), findsNothing);
    expect(find.text('Izgara tavuk'), findsNothing);
  });

  testWidgets('izin reddedilince çökmez ve ayar yolu sunar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaPermissionGatewayProvider.overrideWithValue(const _Denied()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const PhotoLogPage(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('photo-camera')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorPermission), findsOneWidget);
    expect(find.text(l10n.barcodeOpenSettings), findsOneWidget);
  });

  testWidgets('konuşma tanıma yoksa sahte metin yazılmaz', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaPermissionGatewayProvider.overrideWithValue(const _Granted()),
          speechInputServiceProvider.overrideWithValue(
            const MockSpeechInputService(available: false),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const VoiceLogPage(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('voice-mic')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.captureErrorSpeechUnavailable), findsOneWidget);
    expect(find.text(SpokenMealParser.samplePhrase), findsNothing);
  });
}

class _Granted implements MediaPermissionGateway {
  const _Granted();

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<MediaAccess> requestCamera() async => MediaAccess.granted;

  @override
  Future<MediaAccess> requestMicrophone() async => MediaAccess.granted;

  @override
  Future<MediaAccess> requestPhotos() async => MediaAccess.granted;
}

class _Denied implements MediaPermissionGateway {
  const _Denied();

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<MediaAccess> requestCamera() async => MediaAccess.denied;

  @override
  Future<MediaAccess> requestMicrophone() async => MediaAccess.denied;

  @override
  Future<MediaAccess> requestPhotos() async => MediaAccess.denied;
}

class _JpegPicker implements PhotoPickerService {
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    return PickedPhoto(bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]));
  }

  @override
  bool supports(PhotoSource source) => true;
}
