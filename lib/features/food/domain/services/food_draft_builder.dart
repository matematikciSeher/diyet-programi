import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/user_profile.dart';
import '../models/food_log_draft.dart';
import '../models/vision_food_candidate.dart';
import '../repositories/food_repository.dart';
import 'dietary_conflict.dart';
import 'food_match_service.dart';
import 'portion_resolver.dart';
import 'spoken_meal_parser.dart';

/// Adayları katalogla eşleştirir. Günlüğe yazmaz ve yeni [Food] oluşturmaz.
class FoodDraftBuilder {
  const FoodDraftBuilder({FoodMatchService? matcher})
    : _matcher = matcher ?? const FoodMatchService();

  final FoodMatchService _matcher;

  Future<List<FoodLogDraft>> fromVision(
    FoodRepository foods,
    List<VisionFoodCandidate> candidates, {
    UserProfile? profile,
  }) async {
    final drafts = <FoodLogDraft>[];
    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final match = await _matcher.resolve(
        foods,
        foodId: candidate.foodId,
        name: candidate.name,
      );
      drafts.add(
        _draft(
          localId: 'vision-$i-${candidate.name.hashCode}',
          queryName: candidate.name,
          match: match,
          quantity: candidate.estimatedGrams,
          unit: candidate.estimatedGrams == null ? null : PortionUnit.gram,
          quantityAmbiguous: candidate.estimatedGrams == null,
          estimated: candidate.estimatedGrams != null,
          confidence: candidate.confidence,
          source: FoodSource.aiPhoto,
          profile: profile,
        ),
      );
    }
    return drafts;
  }

  Future<List<FoodLogDraft>> fromSpeech(
    FoodRepository foods,
    List<SpokenFoodMention> mentions, {
    UserProfile? profile,
  }) async {
    final drafts = <FoodLogDraft>[];
    for (var i = 0; i < mentions.length; i++) {
      final mention = mentions[i];
      final match = await _matcher.resolve(foods, name: mention.name);
      drafts.add(
        _draft(
          localId: 'voice-$i-${mention.name.hashCode}',
          queryName: mention.name,
          match: match,
          quantity: mention.quantity,
          unit: mention.unit,
          quantityAmbiguous: mention.quantityAmbiguous,
          estimated: false,
          spokenUnitKey: mention.spokenUnitKey,
          confidence: null,
          source: FoodSource.voice,
          profile: profile,
        ),
      );
    }
    return drafts;
  }

  FoodLogDraft relink(
    FoodLogDraft draft,
    Food food, {
    UserProfile? profile,
  }) {
    final ambiguous = draft.quantity <= 0;
    return _apply(
      draft.copyWith(
        food: food,
        matchStatus: FoodMatchStatus.matched,
        options: const [],
        restrictionAcknowledged: false,
      ),
      food,
      quantity: ambiguous ? null : draft.quantity,
      unit: draft.unit,
      quantityAmbiguous: ambiguous,
      estimated: draft.source == FoodSource.aiPhoto && draft.unit == PortionUnit.gram,
      profile: profile,
    );
  }

  FoodLogDraft applyMatch(
    FoodLogDraft draft,
    FoodMatch match, {
    UserProfile? profile,
  }) {
    final food = match.food;
    if (food != null) return relink(draft, food, profile: profile);
    return draft.copyWith(
      clearFood: true,
      options: match.options,
      matchStatus: match.status,
      needsAmount: true,
      clearBaseAmount: true,
      allergyConflict: false,
      dislikeConflict: false,
      dietConflict: false,
      restrictionAcknowledged: false,
    );
  }

  FoodLogDraft withGrams(FoodLogDraft draft, double grams) {
    return draft.copyWith(
      quantity: grams,
      unit: PortionUnit.gram,
      baseAmount: grams,
      needsAmount: grams <= 0,
      assumption: false,
      clearSpokenUnit: true,
    );
  }

  FoodLogDraft _draft({
    required String localId,
    required String queryName,
    required FoodMatch match,
    required double? quantity,
    required PortionUnit? unit,
    required bool quantityAmbiguous,
    required bool estimated,
    required FoodSource source,
    required UserProfile? profile,
    double? confidence,
    String? spokenUnitKey,
  }) {
    final base = FoodLogDraft(
      localId: localId,
      queryName: queryName,
      food: match.food,
      options: match.options,
      matchStatus: match.status,
      quantity: quantity ?? 0,
      unit: unit ?? PortionUnit.gram,
      spokenUnitKey: spokenUnitKey,
      source: source,
      confidence: confidence,
      needsAmount: true,
    );
    final food = match.food;
    if (food == null) return base;
    return _apply(
      base,
      food,
      quantity: quantity,
      unit: unit,
      quantityAmbiguous: quantityAmbiguous,
      estimated: estimated,
      profile: profile,
    );
  }

  FoodLogDraft _apply(
    FoodLogDraft draft,
    Food food, {
    required double? quantity,
    required PortionUnit? unit,
    required bool quantityAmbiguous,
    required bool estimated,
    required UserProfile? profile,
  }) {
    final portion = resolvePortion(
      food: food,
      quantity: quantity,
      unit: unit,
      quantityAmbiguous: quantityAmbiguous,
      estimated: estimated,
    );
    final flags = profile == null
        ? const DietaryFlags()
        : dietaryFlagsFor(
            food: food,
            allergies: profile.allergies,
            dislikedFoods: profile.dislikedFoods,
            dietType: profile.dietType,
          );
    return draft.copyWith(
      food: food,
      quantity: portion.quantity,
      unit: portion.unit,
      baseAmount: portion.baseAmount,
      clearBaseAmount: portion.baseAmount == null,
      assumption: portion.assumption,
      needsAmount: portion.needsAmount,
      allergyConflict: flags.allergy,
      dislikeConflict: flags.dislike,
      dietConflict: flags.diet,
    );
  }
}
