import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../meals/domain/repositories/meal_log_repository.dart';
import '../models/food_log_draft.dart';
import '../repositories/food_repository.dart';
import '../services/capture_submission_guard.dart';
import '../services/food_calculation_service.dart';
import '../services/food_capture_codes.dart';
import '../services/food_match_service.dart';
import '../services/portion_resolver.dart';

/// Onaylanmış adayları [MealEntry] olarak yazar.
///
/// AI günlüğü doğrudan değiştirmez. Besin değerleri [FoodCalculationService]
/// ile hesaplanır. Fotoğraf ve ses bu kayda girmez.
class ConfirmCapturedFoods {
  ConfirmCapturedFoods({
    required MealLogRepository meals,
    required FoodRepository foods,
    required FoodCalculationService calculator,
    required DateTime Function() clock,
    CaptureSubmissionGuard? guard,
  }) : _meals = meals,
       _foods = foods,
       _calculator = calculator,
       _clock = clock,
       _guard = guard ?? CaptureSubmissionGuard();

  final MealLogRepository _meals;
  final FoodRepository _foods;
  final FoodCalculationService _calculator;
  final DateTime Function() _clock;
  final CaptureSubmissionGuard _guard;

  Future<Result<List<MealEntry>>> call({
    required List<FoodLogDraft> drafts,
    required MealType? mealType,
    required String submissionId,
    DateTime? day,
    bool confirmed = false,
  }) async {
    if (!confirmed) {
      return Result.failure(
        foodCaptureFailure(FoodCaptureCodes.confirmationRequired),
      );
    }
    if (mealType == null) {
      return Result.failure(foodCaptureFailure(FoodCaptureCodes.mealRequired));
    }
    if (drafts.isEmpty) {
      return Result.failure(foodCaptureFailure(FoodCaptureCodes.emptyResponse));
    }
    if (!_guard.claim(submissionId)) {
      return Result.failure(foodCaptureFailure(FoodCaptureCodes.duplicate));
    }
    for (final draft in drafts) {
      if (draft.matchStatus == FoodMatchStatus.ambiguous && draft.food == null) {
        _guard.release(submissionId);
        return Result.failure(foodCaptureFailure(FoodCaptureCodes.ambiguousFood));
      }
      if (draft.food == null || draft.matchStatus == FoodMatchStatus.notFound) {
        _guard.release(submissionId);
        return Result.failure(foodCaptureFailure(FoodCaptureCodes.foodNotFound));
      }
      if (!draft.canSave) {
        _guard.release(submissionId);
        final code = draft.hasRestriction && !draft.restrictionAcknowledged
            ? FoodCaptureCodes.allergyConflict
            : draft.needsAmount
            ? FoodCaptureCodes.ambiguousFood
            : FoodCaptureCodes.foodNotFound;
        return Result.failure(foodCaptureFailure(code));
      }
    }

    final now = _clock();
    final at = day == null ? now : day.withTimeOf(now);
    final saved = <MealEntry>[];
    for (final draft in drafts) {
      final food = draft.food!;
      final selection = selectionForDraft(
        food: food,
        quantity: draft.quantity,
        unit: draft.unit,
        baseAmount: draft.baseAmount,
        needsAmount: draft.needsAmount,
      );
      if (selection == null) {
        _guard.release(submissionId);
        for (final entry in saved) {
          await _meals.deleteEntry(entry.id);
        }
        return Result.failure(foodCaptureFailure(FoodCaptureCodes.ambiguousFood));
      }
      final result = await _meals.addEntry(
        MealEntry(
          id: '',
          dayKey: '',
          mealType: mealType,
          name: food.name,
          quantityGrams:
              _calculator.gramsFor(food, selection) ?? selection.baseAmount,
          nutrition: _calculator.nutritionFor(food, selection),
          loggedAt: at,
          foodId: food.id,
          recipeId: food.isRecipe ? food.id : null,
          quantity: selection.quantity,
          unit: selection.portion.unit,
          source: draft.source,
          tags: food.tags,
        ),
      );
      if (result case Err(:final failure)) {
        _guard.release(submissionId);
        for (final entry in saved) {
          await _meals.deleteEntry(entry.id);
        }
        return Result.failure(failure);
      }
      final entry = result.valueOrNull!;
      saved.add(entry);
      await _foods.recordRecent(food, selection, at: now);
    }
    _guard.succeed(submissionId);
    return Result.success(saved);
  }
}
