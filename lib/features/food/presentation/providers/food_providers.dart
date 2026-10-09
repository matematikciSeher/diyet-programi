import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/food.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/recent_food.dart';
import '../../domain/services/food_calculation_service.dart';
import '../../domain/services/food_search_service.dart';
import '../../domain/usecases/log_food.dart';

final foodCalculationServiceProvider = Provider<FoodCalculationService>(
  (ref) => const FoodCalculationService(),
);

final foodSearchServiceProvider = Provider<FoodSearchService>(
  (ref) => const FoodSearchService(),
);

/// Arama sonuçları; sorgu boşsa boş liste.
final foodSearchResultsProvider = FutureProvider.autoDispose
    .family<List<Food>, String>((ref, query) async {
      final result = await ref.watch(foodRepositoryProvider).search(query);
      return result.when(
        success: (foods) => foods,
        failure: (failure) => throw failure,
      );
    });

final foodByIdProvider = FutureProvider.autoDispose.family<Food?, String>((
  ref,
  id,
) async {
  final result = await ref.watch(foodRepositoryProvider).getById(id);
  return result.when(success: (food) => food, failure: (f) => throw f);
});

final recentFoodsProvider = StreamProvider<List<RecentFood>>(
  (ref) => ref.watch(foodRepositoryProvider).watchRecents(),
);

final favoriteFoodsProvider = StreamProvider<List<Food>>(
  (ref) => ref.watch(foodRepositoryProvider).watchFavorites(),
);

final favoriteFoodIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final food in ref.watch(favoriteFoodsProvider).value ?? const <Food>[])
      food.id,
  },
);

/// Kullanıcının oluşturduğu yiyecekler ve tarifler.
final customFoodsProvider = StreamProvider<List<Food>>(
  (ref) => ref.watch(foodRepositoryProvider).watchCustomFoods(),
);

final logFoodProvider = Provider<LogFood>(
  (ref) => LogFood(
    meals: ref.watch(mealLogRepositoryProvider),
    foods: ref.watch(foodRepositoryProvider),
    calculator: ref.watch(foodCalculationServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);
