import 'dart:convert';

import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:diyet_programi/features/onboarding/domain/models/onboarding_step.dart';
import 'package:diyet_programi/features/onboarding/domain/onboarding_validator.dart';
import 'package:diyet_programi/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:diyet_programi/features/onboarding/presentation/providers/onboarding_flow_controller.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/repositories/user_profile_repository.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const completeDraft = OnboardingDraft(
  currentStep: OnboardingStep.summary,
  name: '  Ayşe ',
  goal: GoalType.loseWeight,
  gender: Gender.female,
  age: 30,
  height: 165,
  weight: 70,
  targetWeight: 62,
  activityLevel: ActivityLevel.moderate,
  exerciseFrequency: ExerciseFrequency.threeToFour,
  dietType: DietType.omnivore,
  allergies: ['gluten'],
  mealsPerDay: 3,
  breakfastPreference: BreakfastPreference.always,
  fastingPreference: FastingPreference.none,
);

void main() {
  group('OnboardingValidator', () {
    const base = OnboardingDraft(
      goal: GoalType.loseWeight,
      height: 170,
      weight: 80,
    );

    OnboardingErrorType? typeOf(OnboardingStep step, OnboardingDraft d) =>
        OnboardingValidator.validate(step, d)?.type;

    test('seçim ve değer zorunluluğu', () {
      expect(
        typeOf(OnboardingStep.gender, base),
        OnboardingErrorType.selectionRequired,
      );
      expect(
        typeOf(OnboardingStep.age, base),
        OnboardingErrorType.valueRequired,
      );
      expect(
        typeOf(OnboardingStep.age, base.copyWith(age: 12)),
        OnboardingErrorType.outOfRange,
      );
      expect(typeOf(OnboardingStep.age, base.copyWith(age: 30)), isNull);
      expect(typeOf(OnboardingStep.name, base), isNull);
      expect(typeOf(OnboardingStep.allergies, base), isNull);
    });

    test('hedef kilo hedefle tutarlı ve sağlıklı olmalı', () {
      expect(
        typeOf(OnboardingStep.targetWeight, base.copyWith(targetWeight: 85)),
        OnboardingErrorType.targetMustBeBelowCurrent,
      );
      final low = OnboardingValidator.validate(
        OnboardingStep.targetWeight,
        base.copyWith(targetWeight: 45),
      );
      expect(low?.type, OnboardingErrorType.targetBelowHealthyWeight);
      expect(low?.min, closeTo(53.5, 0.1));
      expect(
        typeOf(OnboardingStep.targetWeight, base.copyWith(targetWeight: 70)),
        isNull,
      );
      expect(
        typeOf(
          OnboardingStep.targetWeight,
          base.copyWith(goal: GoalType.gainWeight, targetWeight: 80),
        ),
        OnboardingErrorType.targetMustBeAboveCurrent,
      );
    });

    test('hedef tarih geçmişte olamaz', () {
      final now = DateTime(2026, 9, 28, 15);
      expect(
        OnboardingValidator.validate(
          OnboardingStep.targetDate,
          base.copyWith(targetDate: DateTime(2026, 9, 28)),
          now: now,
        )?.type,
        OnboardingErrorType.targetDateInPast,
      );
      expect(
        OnboardingValidator.validate(
          OnboardingStep.targetDate,
          base.copyWith(targetDate: DateTime(2026, 12, 1)),
          now: now,
        ),
        isNull,
      );
    });

    test('kilo korumada hedef kilo ve tarih adımları atlanır', () {
      final flow = OnboardingStep.flowFor(GoalType.maintainWeight);
      expect(flow, isNot(contains(OnboardingStep.targetWeight)));
      expect(flow, isNot(contains(OnboardingStep.targetDate)));
      expect(
        OnboardingStep.flowFor(GoalType.loseWeight),
        contains(OnboardingStep.targetWeight),
      );
    });
  });

  test('taslak JSON gidiş-dönüşü ve alan temizleme', () {
    expect(OnboardingDraft.fromJson(completeDraft.toJson()), completeDraft);
    final withDate = completeDraft.copyWith(targetDate: DateTime(2027));
    expect(withDate.copyWith(targetDate: null).targetDate, isNull);
    expect(withDate.copyWith(age: 31).targetDate, DateTime(2027));
  });

  group('OnboardingFlowController', () {
    late InMemoryKeyValueStorage storage;
    late ProviderContainer container;

    ProviderContainer create() {
      final c = ProviderContainer(
        overrides: [keyValueStorageProvider.overrideWithValue(storage)],
      );
      c.listen(onboardingFlowProvider, (_, _) {});
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      storage = InMemoryKeyValueStorage();
      container = create();
    });

    OnboardingFlowController ctrl() =>
        container.read(onboardingFlowProvider.notifier);
    OnboardingFlowState state() => container.read(onboardingFlowProvider);

    test('geçersiz adımda ilerlemez ve hatayı gösterir', () {
      ctrl().skipIntro();
      expect(state().step, OnboardingStep.name);
      expect(ctrl().next(), isTrue);
      expect(state().step, OnboardingStep.goal);

      expect(ctrl().next(), isFalse);
      expect(state().visibleError?.type, OnboardingErrorType.selectionRequired);

      ctrl().update((d) => d.copyWith(goal: GoalType.maintainWeight));
      expect(state().visibleError, isNull);
      expect(ctrl().next(), isTrue);
      expect(state().step, OnboardingStep.gender);
      expect(state().questions, isNot(contains(OnboardingStep.targetWeight)));

      ctrl().back();
      expect(state().step, OnboardingStep.goal);
      expect(state().isForward, isFalse);
    });

    test('kaldığı yerden devam eder', () {
      ctrl()
        ..skipIntro()
        ..next()
        ..update((d) => d.copyWith(goal: GoalType.loseWeight))
        ..next();
      expect(state().step, OnboardingStep.gender);

      final restored = create().read(onboardingFlowProvider);
      expect(restored.step, OnboardingStep.gender);
      expect(restored.draft.goal, GoalType.loseWeight);
    });

    test(
      'özet adımına eksik veriyle dönülürse ilk eksik adıma gider',
      () async {
        await storage.setString(
          StorageKeys.onboardingDraft,
          jsonEncode(
            const OnboardingDraft(
              currentStep: OnboardingStep.summary,
              goal: GoalType.loseWeight,
            ).toJson(),
          ),
        );
        expect(
          create().read(onboardingFlowProvider).step,
          OnboardingStep.gender,
        );
      },
    );

    test('bozuk taslak yok sayılır', () async {
      await storage.setString(StorageKeys.onboardingDraft, '{bozuk');
      expect(
        create().read(onboardingFlowProvider).step,
        OnboardingStep.welcome,
      );
    });

    test(
      'tamamlanınca profil kaydedilir, oturum açılır, taslak silinir',
      () async {
        ctrl().update((_) => completeDraft);
        final ok = await ctrl().complete();
        expect(ok, isTrue);

        expect(container.read(onboardingCompletedProvider), isTrue);
        expect(storage.getString(StorageKeys.onboardingDraft), isNull);
        final user = container.read(authServiceProvider).currentUser;
        expect(user, isNotNull);

        final profile =
            (await container.read(userProfileRepositoryProvider).getProfile())
                .valueOrNull!;
        expect(profile.id, user!.uid);
        expect(profile.name, 'Ayşe');
        expect(profile.dailyCalories, 1650);
        expect(profile.maintenanceCalories, 2200);
        expect(profile.proteinGoal, greaterThan(0));
        expect(profile.waterGoal, greaterThan(0));
        expect(profile.allergies, ['gluten']);
        expect(profile.estimatedGoalDate, isNotNull);
      },
    );

    test('eksik veriyle tamamlanamaz', () async {
      ctrl().update(
        (_) => const OnboardingDraft(
          currentStep: OnboardingStep.summary,
          goal: GoalType.loseWeight,
        ),
      );
      expect(await ctrl().complete(), isFalse);
      expect(state().step, OnboardingStep.gender);
      expect(container.read(onboardingCompletedProvider), isFalse);
    });
  });
}
