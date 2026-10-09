import 'dart:async';

import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/core/widgets/skeleton_view.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/recipes/presentation/pages/recipe_detail_page.dart';
import 'package:diyet_programi/features/recipes/presentation/pages/recipes_page.dart';
import 'package:diyet_programi/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const recipe = Recipe(
    id: 'widget-recipe',
    title: 'Widget Bowl',
    description: 'A small bowl.',
    servings: 1,
    prepMinutes: 5,
    cookMinutes: 0,
    nutritionPerServing: NutritionFacts(
      calories: 100,
      proteinG: 8,
      carbsG: 10,
      fatG: 3,
      fiberG: 2,
    ),
    ingredients: [
      RecipeIngredient(name: 'Yogurt', quantity: 100, unit: 'g'),
    ],
    steps: ['Stir.'],
    tags: ['breakfast'],
    mealTypes: [MealType.breakfast],
    category: 'breakfast',
  );

  Widget listApp(
    Stream<List<Recipe>> recipes, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        recipesProvider.overrideWith((ref) => recipes),
        favoriteRecipeIdsProvider.overrideWith(
          (ref) => Stream.value(const <String>{}),
        ),
        recentRecipesProvider.overrideWith(
          (ref) => Stream.value(const <Recipe>[]),
        ),
        recommendedRecipesProvider.overrideWith((ref) async => const <Recipe>[]),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const RecipesPage(),
      ),
    );
  }

  Widget detailApp(RecipeRepositoryImpl repository) {
    return ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const RecipeDetailPage(recipeId: 'widget-recipe'),
      ),
    );
  }

  testWidgets('tarif listesi koyu temada kartı çizer', (tester) async {
    await tester.pumpWidget(
      listApp(Stream.value(const [recipe]), themeMode: ThemeMode.dark),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Widget Bowl'), findsOneWidget);
    final context = tester.element(find.text('Widget Bowl'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('tarif listesi yüklenirken iskelet gösterir', (tester) async {
    final pending = Completer<List<Recipe>>();
    await tester.pumpWidget(listApp(Stream.fromFuture(pending.future)));
    await tester.pump();
    expect(find.byType(SkeletonView), findsOneWidget);
    expect(find.text(l10n.recipeNoResults), findsNothing);
  });

  testWidgets('tarif listesi boş durumda mesaj gösterir', (tester) async {
    await tester.pumpWidget(listApp(Stream.value(const <Recipe>[])));
    await tester.pumpAndSettle();
    expect(find.text(l10n.recipeNoResults), findsOneWidget);
  });

  testWidgets('tarif listesi hata durumunda yeniden dener', (tester) async {
    await tester.pumpWidget(
      listApp(Stream<List<Recipe>>.error(StateError('offline'))),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorGeneric), findsOneWidget);
    expect(find.text(l10n.actionRetry), findsOneWidget);
  });

  testWidgets('ayrıntıda porsiyon seçimi kaloriyi ölçekler', (tester) async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final repository = RecipeRepositoryImpl(db, 'user-1', catalog: const [recipe]);
    await tester.pumpWidget(detailApp(repository));
    await tester.pumpAndSettle();
    expect(find.text('100 kcal'), findsOneWidget);
    final servings = find.byKey(const ValueKey('recipe-servings'));
    await tester.ensureVisible(servings);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: servings, matching: find.text('2')));
    await tester.pumpAndSettle();
    expect(find.text('200 kcal'), findsOneWidget);
    expect(find.text(l10n.recipeDemoNutrition), findsNothing);
  });
}
