import '../../../../shared/models/food.dart';
import '../repositories/food_repository.dart';
import 'food_search_service.dart';

enum FoodMatchStatus { matched, ambiguous, notFound }

/// AI kimliği veya adı katalogda doğrulandıktan sonraki sonuç.
/// Birden fazla aday varsa otomatik seçim yapılmaz.
class FoodMatch {
  const FoodMatch._(this.status, this.food, this.options);

  const FoodMatch.notFound() : this._(FoodMatchStatus.notFound, null, const []);

  factory FoodMatch.matched(Food food) =>
      FoodMatch._(FoodMatchStatus.matched, food, const []);

  factory FoodMatch.ambiguous(List<Food> options) =>
      FoodMatch._(FoodMatchStatus.ambiguous, null, List.unmodifiable(options));

  final FoodMatchStatus status;
  final Food? food;
  final List<Food> options;
}

class FoodMatchService {
  const FoodMatchService({FoodSearchService search = const FoodSearchService()})
    : _search = search;

  final FoodSearchService _search;

  /// Geçerli [foodId] varsa onu kullanır. Geçersiz id kabul edilmez; ada düşülür.
  Future<FoodMatch> resolve(
    FoodRepository foods, {
    String? foodId,
    required String name,
  }) async {
    final id = foodId?.trim();
    if (id != null && id.isNotEmpty) {
      final byId = await foods.getById(id);
      final food = byId.valueOrNull;
      if (byId.isSuccess && food != null && food.id == id) {
        return FoodMatch.matched(food);
      }
    }
    final searched = await foods.search(name);
    var pool = searched.isSuccess ? searched.valueOrNull! : const <Food>[];
    if (pool.isEmpty) {
      final local = await foods.suggestions(name);
      if (local.isSuccess) pool = local.valueOrNull!;
    }
    return matchName(name, pool);
  }

  /// exact (normalize ad) → tekil yerel/fuzzy sonuç → birden fazlaysa seçim.
  FoodMatch matchName(String name, Iterable<Food> foods) {
    final query = FoodSearchService.normalize(name);
    if (query.isEmpty) return const FoodMatch.notFound();
    final pool = <String, Food>{};
    for (final food in foods) {
      pool.putIfAbsent(food.id, () => food);
    }
    final values = pool.values.toList();
    final exact = values
        .where((food) => FoodSearchService.normalize(food.name) == query)
        .toList();
    if (exact.length == 1) return FoodMatch.matched(exact.single);
    if (exact.length > 1) return FoodMatch.ambiguous(exact);
    final ranked = _search.rank(values, name);
    if (ranked.isEmpty) return const FoodMatch.notFound();
    if (ranked.length == 1) return FoodMatch.matched(ranked.single);
    return FoodMatch.ambiguous(ranked);
  }
}
