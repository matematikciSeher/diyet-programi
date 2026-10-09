import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/services/nutrition/nutrition_calculator.dart';
import 'models/onboarding_draft.dart';
import 'models/onboarding_step.dart';

enum OnboardingErrorType {
  selectionRequired,
  valueRequired,
  outOfRange,
  targetMustBeBelowCurrent,
  targetMustBeAboveCurrent,
  targetBelowHealthyWeight,
  targetDateInPast,
}

class OnboardingValidationError extends Equatable {
  const OnboardingValidationError(this.type, {this.min, this.max});

  final OnboardingErrorType type;
  final num? min;
  final num? max;

  @override
  List<Object?> get props => [type, min, max];
}

/// Her adım için saf doğrulama kuralları. Hata yoksa `null`.
abstract final class OnboardingValidator {
  static OnboardingValidationError? validate(
    OnboardingStep step,
    OnboardingDraft draft, {
    DateTime? now,
  }) {
    return switch (step) {
      OnboardingStep.goal => _selected(draft.goal),
      OnboardingStep.gender => _selected(draft.gender),
      OnboardingStep.age => _range(
        draft.age,
        AppConstants.minAge,
        AppConstants.maxAge,
      ),
      OnboardingStep.height => _range(
        draft.height,
        AppConstants.minHeightCm,
        AppConstants.maxHeightCm,
      ),
      OnboardingStep.weight => _range(
        draft.weight,
        AppConstants.minWeightKg,
        AppConstants.maxWeightKg,
      ),
      OnboardingStep.targetWeight => _targetWeight(draft),
      OnboardingStep.activityLevel => _selected(draft.activityLevel),
      OnboardingStep.exerciseFrequency => _selected(draft.exerciseFrequency),
      OnboardingStep.dietType => _selected(draft.dietType),
      OnboardingStep.mealsPerDay => _selected(draft.mealsPerDay),
      OnboardingStep.breakfast => _selected(draft.breakfastPreference),
      OnboardingStep.fasting => _selected(draft.fastingPreference),
      OnboardingStep.water => _range(
        draft.waterGoal,
        AppConstants.minWaterGoalMl,
        AppConstants.maxWaterGoalMl,
        allowNull: true,
      ),
      OnboardingStep.targetDate => _targetDate(draft.targetDate, now),
      OnboardingStep.welcome ||
      OnboardingStep.benefitPlan ||
      OnboardingStep.benefitTracking ||
      OnboardingStep.benefitHabits ||
      OnboardingStep.name ||
      OnboardingStep.allergies ||
      OnboardingStep.dislikedFoods ||
      OnboardingStep.summary => null,
    };
  }

  /// Özet ekranına gelmeden önce akıştaki ilk hatalı adım.
  static OnboardingStep? firstInvalidStep(
    OnboardingDraft draft, {
    DateTime? now,
  }) {
    for (final step in draft.flow) {
      if (validate(step, draft, now: now) != null) return step;
    }
    return null;
  }

  static OnboardingValidationError? _selected(Object? value) => value == null
      ? const OnboardingValidationError(OnboardingErrorType.selectionRequired)
      : null;

  static OnboardingValidationError? _range(
    num? value,
    num min,
    num max, {
    bool allowNull = false,
  }) {
    if (value == null) {
      return allowNull
          ? null
          : const OnboardingValidationError(OnboardingErrorType.valueRequired);
    }
    if (value < min || value > max) {
      return OnboardingValidationError(
        OnboardingErrorType.outOfRange,
        min: min,
        max: max,
      );
    }
    return null;
  }

  static OnboardingValidationError? _targetWeight(OnboardingDraft draft) {
    final base = _range(
      draft.targetWeight,
      AppConstants.minWeightKg,
      AppConstants.maxWeightKg,
    );
    if (base != null) return base;
    final target = draft.targetWeight!;
    final current = draft.weight;
    if (current == null) return null;

    switch (draft.goal) {
      case GoalType.loseWeight:
        if (target >= current) {
          return const OnboardingValidationError(
            OnboardingErrorType.targetMustBeBelowCurrent,
          );
        }
        final height = draft.height;
        if (height != null) {
          final minHealthy = NutritionCalculator.minHealthyWeight(height);
          if (target < minHealthy) {
            return OnboardingValidationError(
              OnboardingErrorType.targetBelowHealthyWeight,
              min: minHealthy,
            );
          }
        }
      case GoalType.gainWeight:
        if (target <= current) {
          return const OnboardingValidationError(
            OnboardingErrorType.targetMustBeAboveCurrent,
          );
        }
      case GoalType.buildMuscle:
        if (target < current) {
          return const OnboardingValidationError(
            OnboardingErrorType.targetMustBeAboveCurrent,
          );
        }
      case GoalType.maintainWeight || GoalType.eatHealthier || null:
        break;
    }
    return null;
  }

  static OnboardingValidationError? _targetDate(DateTime? date, DateTime? now) {
    if (date == null) return null;
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (!date.isAfter(startOfToday)) {
      return const OnboardingValidationError(
        OnboardingErrorType.targetDateInPast,
      );
    }
    return null;
  }
}
