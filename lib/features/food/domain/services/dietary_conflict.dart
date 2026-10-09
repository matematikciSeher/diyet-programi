import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../recipes/domain/services/recipe_suitability.dart';

/// Profildeki alerji, sevmeme ve diyet türü. AI ile doğrulanmaz.
/// Eşleşme bir güvenlik garantisi değildir; kullanıcıya gösterilir.
class DietaryFlags {
  const DietaryFlags({
    this.allergy = false,
    this.dislike = false,
    this.diet = false,
  });

  final bool allergy;
  final bool dislike;
  final bool diet;

  bool get any => allergy || dislike || diet;
}

DietaryFlags dietaryFlagsFor({
  required Food food,
  List<String> allergies = const [],
  List<String> dislikedFoods = const [],
  DietType? dietType,
}) {
  final foldedName = RecipeSuitability.fold(
    '${food.name} ${food.keywords.join(' ')}',
  );
  final found = {
    ...RecipeSuitability.fromFoodId(food.id),
    ...RecipeSuitability.fromName(food.name),
    ...RecipeSuitability.fromName(food.keywords.join(' ')),
  };
  var allergy = false;
  for (final raw in allergies) {
    final parsed = Allergen.tryParse(raw.trim());
    final folded = RecipeSuitability.fold(raw);
    final mapped = parsed?.name ?? _allergyAlias(folded);
    if (mapped != null && found.contains(mapped)) {
      allergy = true;
      break;
    }
    if (mapped == null && folded.length >= 3 && foldedName.contains(folded)) {
      allergy = true;
      break;
    }
  }
  var dislike = false;
  for (final raw in dislikedFoods) {
    final term = RecipeSuitability.fold(raw);
    if (term.isEmpty) continue;
    if (term.length < 3) {
      if (_tokens(foldedName).contains(term)) dislike = true;
    } else if (foldedName.contains(term)) {
      dislike = true;
    }
  }
  return DietaryFlags(
    allergy: allergy,
    dislike: dislike,
    diet: _dietConflict(foldedName, found, dietType),
  );
}

bool _dietConflict(String folded, Set<String> allergens, DietType? diet) {
  if (diet == null || diet == DietType.omnivore) return false;
  final tokens = _tokens(folded);
  final meat = _has(tokens, const [
    'tavuk',
    'hindi',
    'kuzu',
    'dana',
    'kiyma',
    'kofte',
    'sucuk',
    'sosis',
    'et',
  ]);
  final fish =
      allergens.contains(Allergen.fish.name) ||
      _has(tokens, const ['balik', 'somon', 'ton', 'fish', 'salmon']);
  if (diet == DietType.pescatarian) return meat;
  if (diet == DietType.vegetarian) return meat || fish;
  final animal =
      meat ||
      fish ||
      allergens.contains(Allergen.egg.name) ||
      allergens.contains(Allergen.milk.name) ||
      allergens.contains(Allergen.lactose.name) ||
      _has(tokens, const ['bal', 'honey', 'yumurta', 'peynir', 'yogurt', 'sut']);
  return animal;
}

Set<String> _tokens(String folded) => folded
    .split(RegExp(r'[^a-z0-9]+'))
    .where((token) => token.isNotEmpty)
    .toSet();

bool _has(Set<String> tokens, List<String> words) =>
    words.any(tokens.contains);

String? _allergyAlias(String folded) => switch (folded) {
  'yumurta' || 'egg' => Allergen.egg.name,
  'sut' || 'milk' || 'peynir' || 'yogurt' => Allergen.milk.name,
  'laktoz' || 'lactose' => Allergen.lactose.name,
  'gluten' => Allergen.gluten.name,
  'fistik' || 'peanut' => Allergen.peanut.name,
  'ceviz' || 'badem' || 'findik' => Allergen.treeNuts.name,
  'balik' || 'somon' || 'fish' => Allergen.fish.name,
  'karides' || 'midye' => Allergen.shellfish.name,
  'susam' || 'sesame' => Allergen.sesame.name,
  'soya' || 'soy' => Allergen.soy.name,
  _ => null,
};
