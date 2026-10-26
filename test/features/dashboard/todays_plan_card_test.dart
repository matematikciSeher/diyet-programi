import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/dashboard/presentation/widgets/todays_plan_card.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bugünün planı tarif adını İngilizce gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TodaysPlanCard(
            plan: const [
              PlannedMeal(
                id: 'breakfast',
                dayKey: '2026-10-26',
                mealType: MealType.breakfast,
                title: 'Muz ve badem kasesi',
                nutrition: NutritionFacts(calories: 280, proteinG: 12),
                timeMinutes: 8 * 60,
              ),
            ],
            loggedMealTypes: const {},
            onOpenPlan: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Banana and almond bowl'), findsOneWidget);
    expect(find.text('Muz ve badem kasesi'), findsNothing);
  });
}
