import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/repositories/weight_repository_impl.dart';
import '../../domain/usecases/weight_tracker.dart';

final weightTrackerProvider = Provider<WeightTracker>(
  (ref) => WeightTracker(
    weights: ref.watch(weightRepositoryProvider),
    profiles: ref.watch(userProfileRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
