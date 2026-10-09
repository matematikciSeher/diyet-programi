import '../../../../shared/models/enums.dart';

/// Plan önerilerinde filtrelenebilen ana bileşenler. Kullanıcının
/// sevmediği / yiyemediği şeyler ve diyet tipi bu değerlere çevrilir.
enum PlanIngredient {
  chicken,
  redMeat,
  fish,
  shellfish,
  egg,
  milk,
  cheese,
  yogurt,
  legumes,
  gluten,
  oats,
  nuts,
  peanut,
  sesame,
  soy,
  eggplant,
  mushroom;

  static const dairy = {milk, cheese, yogurt};
  static const meat = {chicken, redMeat};
  static const seafood = {fish, shellfish};

  /// Diyet tipinin dışarıda bıraktığı bileşenler.
  static Set<PlanIngredient> excludedByDiet(DietType? diet) => switch (diet) {
    DietType.vegetarian => {...meat, ...seafood},
    DietType.vegan => {...meat, ...seafood, egg, ...dairy},
    DietType.pescatarian => meat,
    DietType.omnivore || null => const {},
  };

  static Set<PlanIngredient> forAllergen(Allergen allergen) =>
      switch (allergen) {
        Allergen.gluten => {gluten, oats},
        Allergen.lactose || Allergen.milk => dairy,
        Allergen.egg => {egg},
        Allergen.peanut => {peanut},
        Allergen.treeNuts => {nuts},
        Allergen.soy => {soy},
        Allergen.fish => {fish},
        Allergen.shellfish => {shellfish},
        Allergen.sesame => {sesame},
      };
}
