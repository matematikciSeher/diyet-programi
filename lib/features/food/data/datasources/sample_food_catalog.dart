import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';

/// ÖRNEK VERİ — yalnızca geliştirme ve demo amaçlıdır.
///
/// Besin değerleri 100 g içindir ve USDA FoodData Central (SR Legacy)
/// kayıtlarından yuvarlanarak alınmıştır; porsiyon ağırlıkları da aynı
/// kaynağın ev ölçüleridir. Türkiye'deki ürünler tarif ve üretim farkları
/// nedeniyle farklılık gösterebilir. Gerçek bir yiyecek veritabanı
/// (`FoodDatabaseService`) bağlandığında bu liste kullanılmaz.
abstract final class SampleFoodCatalog {
  static const reference = 'USDA FoodData Central (SR Legacy)';

  /// Demo barkodlar GS1'in mağaza içi kullanıma ayırdığı `200` önekiyle
  /// başlar; gerçek bir ürünle çakışmaz.
  static const demoBarcodes = ['2000000000015', '2000000000022'];

  static Food _food(
    String id,
    String name,
    NutritionFacts per100g, {
    List<FoodPortion> portions = const [],
    List<String> keywords = const [],
    Set<FoodTag> tags = const {},
    double? gramsPerMl,
    String? brand,
    String? barcode,
    FoodSource source = FoodSource.database,
  }) => Food(
    id: 'sample-$id',
    name: name,
    nutritionPer100: per100g,
    gramsPerMl: gramsPerMl,
    portions: portions,
    keywords: keywords,
    tags: tags,
    brand: brand,
    barcode: barcode,
    source: source,
    isSample: true,
    dataReference: reference,
  );

  static const _piece = PortionUnit.piece;
  static const _slice = PortionUnit.slice;
  static const _serving = PortionUnit.serving;
  static const _bowl = PortionUnit.bowl;
  static const _glass = PortionUnit.glass;
  static const _tbsp = PortionUnit.tablespoon;
  static const _tsp = PortionUnit.teaspoon;

  static final List<Food> foods = [
    _food(
      'egg-raw',
      'Yumurta (çiğ)',
      const NutritionFacts(
        calories: 143,
        proteinG: 12.6,
        carbsG: 0.7,
        fatG: 9.5,
        fiberG: 0,
        sugarG: 0.4,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 50, description: 'büyük boy'),
      ],
      keywords: const ['egg'],
    ),
    _food(
      'egg-boiled',
      'Haşlanmış yumurta',
      const NutritionFacts(
        calories: 155,
        proteinG: 12.6,
        carbsG: 1.1,
        fatG: 10.6,
        fiberG: 0,
        sugarG: 1.1,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 50, description: 'büyük boy'),
      ],
      keywords: const ['yumurta', 'egg', 'boiled'],
    ),
    _food(
      'tomato',
      'Domates',
      const NutritionFacts(
        calories: 18,
        proteinG: 0.9,
        carbsG: 3.9,
        fatG: 0.2,
        fiberG: 1.2,
        sugarG: 2.6,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 123, description: 'orta boy'),
        FoodPortion(unit: _slice, baseAmount: 20),
      ],
      keywords: const ['tomato'],
      tags: const {FoodTag.vegetable},
    ),
    _food(
      'green-pepper',
      'Yeşil biber (dolmalık)',
      const NutritionFacts(
        calories: 20,
        proteinG: 0.9,
        carbsG: 4.6,
        fatG: 0.2,
        fiberG: 1.7,
        sugarG: 2.4,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 119, description: 'orta boy'),
      ],
      keywords: const ['biber', 'pepper'],
      tags: const {FoodTag.vegetable},
    ),
    _food(
      'onion',
      'Kuru soğan',
      const NutritionFacts(
        calories: 40,
        proteinG: 1.1,
        carbsG: 9.3,
        fatG: 0.1,
        fiberG: 1.7,
        sugarG: 4.2,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 110, description: 'orta boy'),
      ],
      keywords: const ['sogan', 'onion'],
      tags: const {FoodTag.vegetable},
    ),
    _food(
      'cucumber',
      'Salatalık',
      const NutritionFacts(
        calories: 15,
        proteinG: 0.7,
        carbsG: 3.6,
        fatG: 0.1,
        fiberG: 0.5,
        sugarG: 1.7,
      ),
      portions: const [
        FoodPortion(unit: _slice, baseAmount: 7),
        FoodPortion(unit: _bowl, baseAmount: 104, description: 'dilimlenmiş'),
      ],
      keywords: const ['cucumber'],
      tags: const {FoodTag.vegetable},
    ),
    _food(
      'olive-oil',
      'Zeytinyağı',
      const NutritionFacts(
        calories: 884,
        proteinG: 0,
        carbsG: 0,
        fatG: 100,
        saturatedFatG: 13.8,
      ),
      portions: const [
        FoodPortion(unit: _tbsp, baseAmount: 13.5),
        FoodPortion(unit: _tsp, baseAmount: 4.5),
      ],
      keywords: const ['yag', 'olive oil'],
    ),
    _food(
      'butter',
      'Tereyağı',
      const NutritionFacts(
        calories: 717,
        proteinG: 0.9,
        carbsG: 0.1,
        fatG: 81.1,
        saturatedFatG: 51.4,
      ),
      portions: const [
        FoodPortion(unit: _tbsp, baseAmount: 14.2),
        FoodPortion(unit: _tsp, baseAmount: 4.7),
      ],
      keywords: const ['butter'],
    ),
    _food(
      'white-bread',
      'Beyaz ekmek',
      const NutritionFacts(
        calories: 266,
        proteinG: 7.6,
        carbsG: 50.6,
        fatG: 3.3,
        fiberG: 2.4,
      ),
      portions: const [FoodPortion(unit: _slice, baseAmount: 25)],
      keywords: const ['bread'],
    ),
    _food(
      'whole-wheat-bread',
      'Tam buğday ekmeği',
      const NutritionFacts(
        calories: 252,
        proteinG: 12.5,
        carbsG: 42.7,
        fatG: 3.5,
        fiberG: 6,
      ),
      portions: const [FoodPortion(unit: _slice, baseAmount: 32)],
      keywords: const ['ekmek', 'bread', 'whole wheat'],
      tags: const {FoodTag.wholeGrain},
    ),
    _food(
      'oats',
      'Yulaf ezmesi',
      const NutritionFacts(
        calories: 379,
        proteinG: 13.2,
        carbsG: 67.7,
        fatG: 6.5,
        fiberG: 10.1,
        sugarG: 1,
      ),
      portions: const [FoodPortion(unit: _glass, baseAmount: 81)],
      keywords: const ['oats', 'oatmeal'],
      tags: const {FoodTag.wholeGrain},
    ),
    _food(
      'rice-cooked',
      'Beyaz pirinç (haşlanmış)',
      const NutritionFacts(
        calories: 130,
        proteinG: 2.7,
        carbsG: 28.2,
        fatG: 0.3,
        fiberG: 0.4,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 158)],
      keywords: const ['pilav', 'rice'],
    ),
    _food(
      'pasta-cooked',
      'Makarna (haşlanmış)',
      const NutritionFacts(
        calories: 158,
        proteinG: 5.8,
        carbsG: 30.9,
        fatG: 0.9,
        fiberG: 1.8,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 140)],
      keywords: const ['pasta', 'spagetti'],
    ),
    _food(
      'lentils-cooked',
      'Mercimek (haşlanmış)',
      const NutritionFacts(
        calories: 116,
        proteinG: 9,
        carbsG: 20.1,
        fatG: 0.4,
        fiberG: 7.9,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 198)],
      keywords: const ['lentil', 'baklagil'],
    ),
    _food(
      'chickpeas-cooked',
      'Nohut (haşlanmış)',
      const NutritionFacts(
        calories: 164,
        proteinG: 8.9,
        carbsG: 27.4,
        fatG: 2.6,
        fiberG: 7.6,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 164)],
      keywords: const ['chickpea', 'baklagil'],
    ),
    _food(
      'chicken-breast',
      'Tavuk göğsü (derisiz, fırında)',
      const NutritionFacts(calories: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
      portions: const [FoodPortion(unit: _serving, baseAmount: 85)],
      keywords: const ['tavuk', 'chicken', 'izgara'],
    ),
    _food(
      'salmon',
      'Somon (çiftlik, pişmiş)',
      const NutritionFacts(
        calories: 206,
        proteinG: 22.1,
        carbsG: 0,
        fatG: 12.4,
      ),
      portions: const [FoodPortion(unit: _serving, baseAmount: 85)],
      keywords: const ['balik', 'salmon', 'fish'],
    ),
    _food(
      'feta',
      'Beyaz peynir (feta)',
      const NutritionFacts(
        calories: 264,
        proteinG: 14.2,
        carbsG: 4.1,
        fatG: 21.3,
        sodiumMg: 1116,
      ),
      portions: const [FoodPortion(unit: _serving, baseAmount: 28.35)],
      keywords: const ['peynir', 'cheese', 'feta'],
    ),
    _food(
      'milk-whole',
      'Süt (tam yağlı)',
      const NutritionFacts(
        calories: 61,
        proteinG: 3.2,
        carbsG: 4.8,
        fatG: 3.3,
        sugarG: 5.1,
      ),
      portions: const [FoodPortion(unit: _glass, baseAmount: 244)],
      gramsPerMl: 1.03,
      keywords: const ['milk'],
    ),
    _food(
      'yogurt-whole',
      'Yoğurt (sade, tam yağlı)',
      const NutritionFacts(
        calories: 61,
        proteinG: 3.5,
        carbsG: 4.7,
        fatG: 3.3,
        sugarG: 4.7,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 245)],
      keywords: const ['yogurt'],
    ),
    _food(
      'apple',
      'Elma',
      const NutritionFacts(
        calories: 52,
        proteinG: 0.3,
        carbsG: 13.8,
        fatG: 0.2,
        fiberG: 2.4,
        sugarG: 10.4,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 182, description: 'orta boy'),
      ],
      keywords: const ['apple', 'meyve'],
      tags: const {FoodTag.fruit},
    ),
    _food(
      'banana',
      'Muz',
      const NutritionFacts(
        calories: 89,
        proteinG: 1.1,
        carbsG: 22.8,
        fatG: 0.3,
        fiberG: 2.6,
        sugarG: 12.2,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 118, description: 'orta boy'),
      ],
      keywords: const ['banana', 'meyve'],
      tags: const {FoodTag.fruit},
    ),
    _food(
      'orange',
      'Portakal',
      const NutritionFacts(
        calories: 47,
        proteinG: 0.9,
        carbsG: 11.8,
        fatG: 0.1,
        fiberG: 2.4,
        sugarG: 9.4,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 131, description: 'orta boy'),
      ],
      keywords: const ['orange', 'meyve'],
      tags: const {FoodTag.fruit},
    ),
    _food(
      'orange-juice',
      'Portakal suyu (taze sıkılmış)',
      const NutritionFacts(
        calories: 45,
        proteinG: 0.7,
        carbsG: 10.4,
        fatG: 0.2,
        fiberG: 0.2,
        sugarG: 8.4,
      ),
      portions: const [FoodPortion(unit: _glass, baseAmount: 248)],
      gramsPerMl: 1.05,
      keywords: const ['meyve suyu', 'juice'],
    ),
    _food(
      'walnuts',
      'Ceviz içi',
      const NutritionFacts(
        calories: 654,
        proteinG: 15.2,
        carbsG: 13.7,
        fatG: 65.2,
        fiberG: 6.7,
      ),
      portions: const [
        FoodPortion(unit: _serving, baseAmount: 28.35, description: '14 yarım'),
      ],
      keywords: const ['walnut', 'kuruyemis'],
    ),
    _food(
      'almonds',
      'Badem',
      const NutritionFacts(
        calories: 579,
        proteinG: 21.2,
        carbsG: 21.6,
        fatG: 49.9,
        fiberG: 12.5,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 1.2),
        FoodPortion(unit: _serving, baseAmount: 28.35, description: '23 adet'),
      ],
      keywords: const ['almond', 'kuruyemis'],
    ),
    _food(
      'black-olives',
      'Siyah zeytin (konserve)',
      const NutritionFacts(
        calories: 115,
        proteinG: 0.8,
        carbsG: 6.3,
        fatG: 10.7,
        fiberG: 3.2,
      ),
      portions: const [
        FoodPortion(unit: _piece, baseAmount: 4.4, description: 'iri'),
      ],
      keywords: const ['zeytin', 'olive'],
    ),
    _food(
      'honey',
      'Bal',
      const NutritionFacts(
        calories: 304,
        proteinG: 0.3,
        carbsG: 82.4,
        fatG: 0,
        fiberG: 0.2,
        sugarG: 82.1,
      ),
      portions: const [
        FoodPortion(unit: _tbsp, baseAmount: 21),
        FoodPortion(unit: _tsp, baseAmount: 7),
      ],
      keywords: const ['honey'],
    ),
    // Demo barkodlu ürünler: değerler yukarıdaki genel kayıtlarla aynıdır,
    // yalnızca barkod akışını denemek içindir.
    _food(
      'demo-yogurt',
      'Sade yoğurt (örnek ürün)',
      const NutritionFacts(
        calories: 61,
        proteinG: 3.5,
        carbsG: 4.7,
        fatG: 3.3,
        sugarG: 4.7,
      ),
      portions: const [FoodPortion(unit: _bowl, baseAmount: 245)],
      brand: 'Demo',
      barcode: demoBarcodes[0],
      source: FoodSource.barcode,
    ),
    _food(
      'demo-oats',
      'Yulaf ezmesi (örnek ürün)',
      const NutritionFacts(
        calories: 379,
        proteinG: 13.2,
        carbsG: 67.7,
        fatG: 6.5,
        fiberG: 10.1,
        sugarG: 1,
      ),
      portions: const [FoodPortion(unit: _glass, baseAmount: 81)],
      brand: 'Demo',
      barcode: demoBarcodes[1],
      tags: const {FoodTag.wholeGrain},
      source: FoodSource.barcode,
    ),
  ];
}
