import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../nutrition/data/repositories/nutrition_goal_history_repository_impl.dart';
import '../../../nutrition/domain/usecases/apply_calorie_target.dart';

final applyCalorieTargetProvider = Provider<ApplyCalorieTarget>(
  (ref) => ApplyCalorieTarget(
    profiles: ref.watch(userProfileRepositoryProvider),
    history: ref.watch(nutritionGoalHistoryRepositoryProvider),
    targets: ref.watch(profileTargetsServiceProvider),
    storage: ref.watch(keyValueStorageProvider),
    clock: ref.watch(clockProvider),
  ),
);
