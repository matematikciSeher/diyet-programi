import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/models/recipe_category.dart';

extension RecipeCategoryL10n on RecipeCategory {
  String label(AppLocalizations l10n) => switch (this) {
    RecipeCategory.breakfast => l10n.recipeCategoryBreakfast,
    RecipeCategory.lunch => l10n.recipeCategoryLunch,
    RecipeCategory.dinner => l10n.recipeCategoryDinner,
    RecipeCategory.snack => l10n.recipeCategorySnack,
    RecipeCategory.dessert => l10n.recipeCategoryDessert,
    RecipeCategory.drink => l10n.recipeCategoryDrink,
    RecipeCategory.highProtein => l10n.recipeCategoryHighProtein,
    RecipeCategory.lowCalorie => l10n.recipeCategoryLowCalorie,
  };

  IconData get icon => switch (this) {
    RecipeCategory.breakfast => Icons.free_breakfast_outlined,
    RecipeCategory.lunch => Icons.lunch_dining_outlined,
    RecipeCategory.dinner => Icons.dinner_dining_outlined,
    RecipeCategory.snack => Icons.cookie_outlined,
    RecipeCategory.dessert => Icons.icecream_outlined,
    RecipeCategory.drink => Icons.local_drink_outlined,
    RecipeCategory.highProtein => Icons.fitness_center_rounded,
    RecipeCategory.lowCalorie => Icons.eco_outlined,
  };
}
