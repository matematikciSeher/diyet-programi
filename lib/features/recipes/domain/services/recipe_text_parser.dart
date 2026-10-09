import '../../../../shared/models/recipe.dart';

/// Tarif formundaki çok satırlı metinleri modele çevirir.
abstract final class RecipeTextParser {
  static final _quantityFirst = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(\S+)\s+(.+)$',
  );

  /// Her satır bir malzeme: "2 adet yumurta", "150 g lor peyniri" ya da
  /// yalnızca "tuz". Boş satırlar atlanır.
  static List<RecipeIngredient> ingredients(String text) => [
    for (final raw in text.split('\n'))
      if (raw.trim() case final line when line.isNotEmpty) _ingredient(line),
  ];

  static RecipeIngredient _ingredient(String line) {
    final match = _quantityFirst.firstMatch(line);
    if (match == null) {
      return RecipeIngredient(name: line, quantity: 0, unit: '');
    }
    return RecipeIngredient(
      name: match.group(3)!.trim(),
      quantity: double.parse(match.group(1)!.replaceAll(',', '.')),
      unit: match.group(2)!,
    );
  }

  /// Her satır bir adım; baştaki "1." / "1)" numaraları kaldırılır.
  static List<String> steps(String text) => [
    for (final raw in text.split('\n'))
      if (raw.trim().replaceFirst(RegExp(r'^\d+\s*[.)-]\s*'), '')
          case final step when step.isNotEmpty)
        step,
  ];
}
