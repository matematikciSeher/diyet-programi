import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';

/// Malzeme kimliği ve adından alerjen ile diyet uyumunu çıkarır.
///
/// Etiket tek başına yetmez: alerjen veya hayvansal ürün malzemede varsa
/// tarif uygun sayılmaz.
abstract final class RecipeSuitability {
  static const meatFoodIds = {'sample-chicken-breast', 'chicken-breast'};
  static const fishFoodIds = {'sample-salmon', 'salmon'};
  static const eggFoodIds = {'sample-egg-raw', 'egg-raw', 'sample-egg-boiled', 'egg-boiled'};
  static const dairyFoodIds = {
    'sample-milk-whole',
    'milk-whole',
    'sample-yogurt-whole',
    'yogurt-whole',
    'sample-feta',
    'feta',
    'sample-butter',
    'butter',
    'sample-demo-yogurt',
    'demo-yogurt',
  };
  static const honeyFoodIds = {'sample-honey', 'honey'};
  static const glutenFoodIds = {
    'sample-white-bread',
    'white-bread',
    'sample-whole-wheat-bread',
    'whole-wheat-bread',
    'sample-pasta-cooked',
    'pasta-cooked',
    'sample-oats',
    'oats',
    'sample-demo-oats',
    'demo-oats',
  };
  static const nutFoodIds = {
    'sample-walnuts',
    'walnuts',
    'sample-almonds',
    'almonds',
  };

  static String fold(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static Set<String> allergensOf(Recipe recipe) {
    final found = <String>{...recipe.allergens};
    for (final ingredient in recipe.ingredients) {
      found.addAll(fromFoodId(ingredient.foodId));
      found.addAll(fromName(ingredient.name));
    }
    return found;
  }

  static Set<String> fromFoodId(String? foodId) {
    if (foodId == null || foodId.isEmpty) return const {};
    final id = foodId.startsWith('sample-') ? foodId.substring(7) : foodId;
    final found = <String>{};
    if (eggFoodIds.contains(id) || eggFoodIds.contains(foodId)) {
      found.add(Allergen.egg.name);
    }
    if (dairyFoodIds.contains(id) || dairyFoodIds.contains(foodId)) {
      found
        ..add(Allergen.milk.name)
        ..add(Allergen.lactose.name);
    }
    if (glutenFoodIds.contains(id) || glutenFoodIds.contains(foodId)) {
      found.add(Allergen.gluten.name);
    }
    if (nutFoodIds.contains(id) || nutFoodIds.contains(foodId)) {
      found.add(Allergen.treeNuts.name);
    }
    if (fishFoodIds.contains(id) || fishFoodIds.contains(foodId)) {
      found.add(Allergen.fish.name);
    }
    return found;
  }

  static Set<String> fromName(String name) {
    final n = fold(name);
    final found = <String>{};
    if (_has(n, const ['yumurta', 'egg'])) found.add(Allergen.egg.name);
    if (_has(n, const [
      'sut',
      'yogurt',
      'peynir',
      'tereyag',
      'kaymak',
      'milk',
      'feta',
      'lor',
      'ayran',
    ])) {
      found
        ..add(Allergen.milk.name)
        ..add(Allergen.lactose.name);
    }
    if (_has(n, const ['laktoz', 'lactose'])) found.add(Allergen.lactose.name);
    if (_has(n, const ['gluten', 'ekmek', 'makarna', 'yulaf', 'bulgur', 'un '])) {
      found.add(Allergen.gluten.name);
    }
    if (_has(n, const ['ceviz', 'badem', 'findik', 'walnut', 'almond'])) {
      found.add(Allergen.treeNuts.name);
    }
    if (_has(n, const ['fistik', 'peanut'])) found.add(Allergen.peanut.name);
    if (_has(n, const ['somon', 'balik', 'fish', 'salmon', 'ton'])) {
      found.add(Allergen.fish.name);
    }
    if (_has(n, const ['karides', 'midye', 'shellfish'])) {
      found.add(Allergen.shellfish.name);
    }
    if (_has(n, const ['susam', 'sesame'])) found.add(Allergen.sesame.name);
    if (_has(n, const ['soya', 'soy'])) found.add(Allergen.soy.name);
    return found;
  }

  /// Profildeki alerji adı ya da serbest metin bu tarife uyuyorsa `true`.
  static bool conflictsWithAllergy(Recipe recipe, String allergy) {
    final parsed = Allergen.tryParse(allergy.trim());
    final folded = fold(allergy);
    final mapped = parsed?.name ?? _allergyAlias(folded);
    if (mapped != null && allergensOf(recipe).contains(mapped)) return true;
    if (mapped == null) {
      for (final ingredient in recipe.ingredients) {
        if (_containsTerm(fold(ingredient.name), folded)) return true;
      }
    }
    return false;
  }

  static String? _allergyAlias(String folded) => switch (folded) {
    'yumurta' || 'egg' => Allergen.egg.name,
    'sut' || 'süt' || 'milk' || 'peynir' || 'yogurt' => Allergen.milk.name,
    'laktoz' || 'lactose' => Allergen.lactose.name,
    'gluten' => Allergen.gluten.name,
    'fistik' || 'peanut' => Allergen.peanut.name,
    'ceviz' || 'badem' || 'findik' || 'tree nuts' => Allergen.treeNuts.name,
    'balik' || 'somon' || 'fish' => Allergen.fish.name,
    'karides' || 'midye' || 'shellfish' => Allergen.shellfish.name,
    'susam' || 'sesame' => Allergen.sesame.name,
    'soya' || 'soy' => Allergen.soy.name,
    _ => null,
  };

  static bool matchesDiet(Recipe recipe, DietType? diet) {
    if (diet == null || diet == DietType.omnivore) return true;
    final animal = _hasAnimal(recipe, includeFish: true, includeEggDairyHoney: true);
    final meat = _hasMeat(recipe);
    final fish = _hasFish(recipe);
    return switch (diet) {
      DietType.omnivore => true,
      DietType.pescatarian => !meat,
      DietType.vegetarian => !meat && !fish,
      DietType.vegan => !animal,
    };
  }

  static bool containsDisliked(Recipe recipe, List<String> disliked) {
    for (final raw in disliked) {
      final term = fold(raw);
      if (term.isEmpty) continue;
      for (final ingredient in recipe.ingredients) {
        if (_containsTerm(fold(ingredient.name), term)) return true;
      }
    }
    return false;
  }

  static bool _hasMeat(Recipe recipe) {
    for (final ingredient in recipe.ingredients) {
      final id = ingredient.foodId ?? '';
      if (meatFoodIds.contains(id) || meatFoodIds.contains(_bare(id))) {
        return true;
      }
      if (_has(fold(ingredient.name), const [
        'tavuk',
        'hindi',
        'kuzu',
        'dana',
        'kiyma',
        'kofte',
        'et ',
      ])) {
        return true;
      }
      final tokens = fold(ingredient.name).split(RegExp(r'[^a-z0-9]+'));
      if (tokens.contains('et')) return true;
    }
    return false;
  }

  static bool _hasFish(Recipe recipe) {
    for (final ingredient in recipe.ingredients) {
      final id = ingredient.foodId ?? '';
      if (fishFoodIds.contains(id) || fishFoodIds.contains(_bare(id))) {
        return true;
      }
      if (_has(fold(ingredient.name), const ['somon', 'balik', 'ton', 'karides'])) {
        return true;
      }
    }
    return false;
  }

  static bool _hasAnimal(
    Recipe recipe, {
    required bool includeFish,
    required bool includeEggDairyHoney,
  }) {
    if (_hasMeat(recipe)) return true;
    if (includeFish && _hasFish(recipe)) return true;
    if (!includeEggDairyHoney) return false;
    for (final ingredient in recipe.ingredients) {
      final id = ingredient.foodId ?? '';
      final bare = _bare(id);
      if (eggFoodIds.contains(bare) ||
          dairyFoodIds.contains(bare) ||
          honeyFoodIds.contains(bare)) {
        return true;
      }
      final name = fold(ingredient.name);
      if (_has(name, const [
        'yumurta',
        'sut',
        'yogurt',
        'peynir',
        'tereyag',
        'kaymak',
        'lor',
        'honey',
      ])) {
        return true;
      }
      final tokens = name.split(RegExp(r'[^a-z0-9]+'));
      if (tokens.contains('bal')) return true;
    }
    return false;
  }

  static String _bare(String id) =>
      id.startsWith('sample-') ? id.substring(7) : id;

  static bool _has(String folded, List<String> needles) =>
      needles.any(folded.contains);

  /// Kısa sözcükler ("et") yalnızca kelime olarak eşleşir.
  static bool _containsTerm(String foldedName, String term) {
    if (term.length <= 2) {
      final tokens = foldedName.split(RegExp(r'[^a-z0-9]+'));
      return tokens.contains(term);
    }
    return foldedName.contains(term);
  }
}
