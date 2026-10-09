import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../models/nutrition_goal_history.dart';
import '../repositories/nutrition_goal_history_repository.dart';

/// Kullanıcı onayından sonra kalori/makro hedefini yazar; reddederse eski
/// hedefi korur. Her iki durumda da geçmiş kaydı tutulur.
class ApplyCalorieTarget {
  const ApplyCalorieTarget({
    required UserProfileRepository profiles,
    required NutritionGoalHistoryRepository history,
    required ProfileTargetsService targets,
    required KeyValueStorage storage,
    required DateTime Function() clock,
  }) : _profiles = profiles,
       _history = history,
       _targets = targets,
       _storage = storage,
       _clock = clock;

  final UserProfileRepository _profiles;
  final NutritionGoalHistoryRepository _history;
  final ProfileTargetsService _targets;
  final KeyValueStorage _storage;
  final DateTime Function() _clock;

  Future<Result<UserProfile?>> apply(
    TargetSuggestion suggestion, {
    required GoalChangeReason reason,
  }) => _commit(suggestion, reason: reason, approved: true);

  Future<Result<UserProfile?>> keepCurrent(
    TargetSuggestion suggestion, {
    required GoalChangeReason reason,
  }) => _commit(suggestion, reason: reason, approved: false);

  Future<Result<UserProfile?>> _commit(
    TargetSuggestion suggestion, {
    required GoalChangeReason reason,
    required bool approved,
  }) async {
    final profile = (await _profiles.getProfile()).valueOrNull;
    if (profile == null) return const Result.success(null);
    final now = _clock();
    final next = approved ? _targets.apply(profile, suggestion) : profile;
    if (approved) {
      final saved = await _profiles.saveProfile(next.copyWith(updatedAt: now));
      if (saved case Err(:final failure)) return Result.failure(failure);
    }
    await _history.add(
      NutritionGoalHistory(
        id: '',
        userId: profile.id,
        createdAt: now,
        previousCalories: suggestion.currentCalories,
        newCalories: approved
            ? suggestion.calories
            : (suggestion.currentCalories ?? suggestion.calories),
        approved: approved,
        reason: reason,
        weightKg: suggestion.weightKg ?? profile.weight,
        previousProteinG: suggestion.currentProteinG,
        newProteinG: approved ? suggestion.proteinG : suggestion.currentProteinG,
        previousCarbsG: suggestion.currentCarbsG,
        newCarbsG: approved ? suggestion.carbsG : suggestion.currentCarbsG,
        previousFatG: suggestion.currentFatG,
        newFatG: approved ? suggestion.fatG : suggestion.currentFatG,
      ),
    );
    if (approved) {
      await _storage.remove(StorageKeys.dismissedCalorieTarget(profile.id));
    } else {
      await _storage.setString(
        StorageKeys.dismissedCalorieTarget(profile.id),
        '${suggestion.calories}|${suggestion.weightKg ?? profile.weight}',
      );
    }
    return Result.success(approved ? next : profile);
  }

  bool isDismissed(UserProfile profile, TargetSuggestion suggestion) {
    final raw = _storage.getString(
      StorageKeys.dismissedCalorieTarget(profile.id),
    );
    if (raw == null) return false;
    return raw == '${suggestion.calories}|${suggestion.weightKg ?? profile.weight}';
  }
}
