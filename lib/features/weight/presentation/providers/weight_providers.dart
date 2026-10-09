import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../nutrition/domain/models/nutrition_goal_history.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../domain/services/weight_stats.dart';
import 'target_change_providers.dart';

class WeightRangeController extends Notifier<WeightRange> {
  @override
  WeightRange build() => WeightRange.month;

  void select(WeightRange range) => state = range;
}

final weightRangeProvider =
    NotifierProvider<WeightRangeController, WeightRange>(
      WeightRangeController.new,
    );

/// `null` veri: hiç kilo bilgisi yok (boş durum).
final weightStatsProvider = Provider<AsyncValue<WeightStats?>>((ref) {
  final entries = ref.watch(weightEntriesProvider);
  final profile = ref.watch(userProfileProvider);
  for (final source in <AsyncValue<Object?>>[entries, profile]) {
    if (source.hasError && !source.hasValue) {
      return AsyncError(source.error!, source.stackTrace ?? StackTrace.empty);
    }
  }
  if (!entries.hasValue || !profile.hasValue) return const AsyncLoading();
  return AsyncData(
    WeightStats.compute(
      entries: entries.requireValue,
      profile: profile.value,
      range: ref.watch(weightRangeProvider),
      now: ref.read(clockProvider)(),
    ),
  );
});

/// Kullanıcının bu oturumda "Şimdi değil" dediği öneri tekrar gösterilmez.
class DismissedTargetSuggestion extends Notifier<int?> {
  @override
  int? build() => null;

  void dismiss(int calories) => state = calories;
}

final dismissedTargetSuggestionProvider =
    NotifierProvider<DismissedTargetSuggestion, int?>(
      DismissedTargetSuggestion.new,
    );

/// Güncel kiloya göre yeniden hesaplanmış hedef önerisi.
final targetSuggestionProvider = Provider<TargetSuggestion?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return null;
  final entries = ref.watch(weightEntriesProvider).value;
  final previous = entries != null && entries.length >= 2
      ? entries[1].weightKg
      : profile.startWeight;
  final suggestion = ref
      .watch(profileTargetsServiceProvider)
      .suggest(
        profile,
        now: ref.read(clockProvider)(),
        previousWeightKg: previous == profile.weight ? null : previous,
      );
  if (suggestion == null) return null;
  if (ref.watch(dismissedTargetSuggestionProvider) == suggestion.calories) {
    return null;
  }
  if (ref.read(applyCalorieTargetProvider).isDismissed(profile, suggestion)) {
    return null;
  }
  return suggestion;
});

/// Öneriyi profile yazar; plan ve dashboard profil akışından güncellenir.
final applyTargetSuggestionProvider =
    Provider<Future<void> Function(TargetSuggestion)>((ref) {
      return (suggestion) async {
        await ref
            .read(applyCalorieTargetProvider)
            .apply(suggestion, reason: GoalChangeReason.weightChange);
        ref.read(dismissedTargetSuggestionProvider.notifier).dismiss(
          suggestion.calories,
        );
      };
    });

final keepCurrentTargetProvider =
    Provider<Future<void> Function(TargetSuggestion)>((ref) {
      return (suggestion) async {
        await ref
            .read(applyCalorieTargetProvider)
            .keepCurrent(suggestion, reason: GoalChangeReason.weightChange);
        ref.read(dismissedTargetSuggestionProvider.notifier).dismiss(
          suggestion.calories,
        );
      };
    });
