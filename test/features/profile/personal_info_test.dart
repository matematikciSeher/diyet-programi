import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/plan_ingredient.dart';
import 'package:diyet_programi/features/profile/presentation/pages/personal_info_page.dart';
import 'package:diyet_programi/features/profile/presentation/providers/personal_info_providers.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/repositories/user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late InMemoryKeyValueStorage storage;
  late ProviderContainer container;

  setUp(() {
    db = InMemoryDocumentDatabase();
    storage = InMemoryKeyValueStorage();
    container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
        documentDatabaseProvider.overrideWithValue(db),
        currentUserIdProvider.overrideWithValue('user-1'),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.dispose();
  });

  test('diyet tipi değişince plan et ve süt ürünü içermez', () async {
    final omnivore = testProfile();
    await container.read(userProfileRepositoryProvider).saveProfile(omnivore);

    final vegan = omnivore.copyWith(dietType: DietType.vegan);
    final result = await container.read(personalInfoActionsProvider).save(vegan);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.planUpdated, isTrue);
    expect(
      (await container.read(userProfileRepositoryProvider).getProfile())
          .valueOrNull!
          .dietType,
      DietType.vegan,
    );

    final plan = await container
        .read(mealPlanRepositoryProvider)
        .watchDay(testNow.startOfDay)
        .first;
    expect(plan, isNotEmpty);
    const banned = {
      ...PlanIngredient.meat,
      ...PlanIngredient.seafood,
      PlanIngredient.egg,
      ...PlanIngredient.dairy,
    };
    expect(plan.any((m) => m.ingredients.any(banned.contains)), isFalse);
  });

  testWidgets('profil yoksa boş durum gösterilir', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PersonalInfoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profil bilgisi yok'), findsOneWidget);
    expect(
      find.textContaining('Onboarding'),
      findsOneWidget,
    );
  });
}
