import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../models/meal_plan_preferences.dart';
import '../models/plan_ingredient.dart';
import '../models/planned_meal.dart';
import '../services/meal_plan_generator.dart';
import '../services/plan_change_parser.dart';

class PlanMealChange extends Equatable {
  const PlanMealChange(this.before, this.after);

  final PlannedMeal before;
  final PlannedMeal after;

  @override
  List<Object?> get props => [before, after];
}

enum PlanChangeKind {
  excluded,
  preferred,
  swapped,
  regenerated,
  dietChanged,
  notUnderstood,
}

/// Bir değişiklik isteğinin sonucu; kullanıcıya verilecek yanıt buradan
/// oluşturulur.
class PlanChangeOutcome extends Equatable {
  const PlanChangeOutcome({
    required this.kind,
    required this.request,
    required this.plan,
    this.changes = const [],
    this.noAlternative = const [],
    this.alreadyMatching = const [],
    this.remember = false,
  });

  final PlanChangeKind kind;
  final PlanChangeRequest request;
  final List<PlannedMeal> plan;
  final List<PlanMealChange> changes;

  /// Kısıtlara uyan alternatif bulunamayan öğünler.
  final List<PlannedMeal> noAlternative;

  /// İstek zaten karşılanıyor: dışlanan bileşeni içermeyen ya da istenen
  /// bileşeni zaten içeren öğünler.
  final List<PlannedMeal> alreadyMatching;

  /// İstek genel bir tercih ("tavuğu sevmiyorum"); sonraki planlarda da
  /// uygulanmalı.
  final bool remember;

  bool get changed => changes.isNotEmpty;

  @override
  List<Object?> get props => [
    kind,
    request,
    plan,
    changes,
    noAlternative,
    alreadyMatching,
    remember,
  ];
}

/// [PlanChangeRequest]'i günün planına uygular.
class ApplyPlanChange {
  const ApplyPlanChange(this._generator);

  final MealPlanGenerator _generator;

  PlanChangeOutcome call({
    required DateTime day,
    required List<PlannedMeal> plan,
    required PlanChangeRequest request,
    required MealPlanPreferences prefs,
    Random? random,
  }) {
    final rng = random ?? Random();
    if (request.isEmpty) {
      return PlanChangeOutcome(
        kind: PlanChangeKind.notUnderstood,
        request: request,
        plan: plan,
      );
    }

    final diet = request.diet;
    final effective = prefs.withExcluded({
      ...request.excluded,
      if (diet != null) ...PlanIngredient.excludedByDiet(diet),
    });

    if (request.regenerateAll) {
      final next = _generator.generateDay(
        day,
        effective,
        seed: rng.nextInt(1 << 31),
      );
      return PlanChangeOutcome(
        kind: PlanChangeKind.regenerated,
        request: request,
        plan: next,
        changes: [
          for (final after in next)
            if (plan.where((m) => m.id == after.id).firstOrNull
                case final before?)
              PlanMealChange(before, after),
        ],
      );
    }

    bool inScope(PlannedMeal m) =>
        request.mealTypes.isEmpty || request.mealTypes.contains(m.mealType);
    final scoped = plan.where(inScope).toList();

    if (request.excluded.isNotEmpty || diet != null) {
      final blocked = effective.excluded;
      return _replace(
        kind: diet != null
            ? PlanChangeKind.dietChanged
            : PlanChangeKind.excluded,
        request: request,
        plan: plan,
        targets: scoped.where((m) => m.ingredients.any(blocked.contains)),
        untouched: scoped.where((m) => !m.ingredients.any(blocked.contains)),
        prefs: effective,
        random: rng,
        remember: request.mealTypes.isEmpty || diet != null,
      );
    }

    if (request.preferred.isNotEmpty) {
      final wanted = request.preferred;
      final present = scoped
          .where((m) => m.ingredients.any(wanted.contains))
          .toList();
      if (present.isNotEmpty) {
        return PlanChangeOutcome(
          kind: PlanChangeKind.preferred,
          request: request,
          plan: plan,
          alreadyMatching: present,
        );
      }
      // Öğün belirtilmediyse en uygun tek bir ana öğün değiştirilir.
      final candidates = request.mealTypes.isEmpty
          ? scoped.where(
              (m) =>
                  m.mealType == MealType.dinner || m.mealType == MealType.lunch,
            )
          : scoped;
      for (final meal in candidates.toList().reversed) {
        final alternative = _generator.alternativeFor(
          meal,
          plan,
          effective,
          preferred: wanted,
          random: rng,
        );
        if (alternative == null) continue;
        return PlanChangeOutcome(
          kind: PlanChangeKind.preferred,
          request: request,
          plan: _replaceIn(plan, {alternative.id: alternative}),
          changes: [PlanMealChange(meal, alternative)],
        );
      }
      return PlanChangeOutcome(
        kind: PlanChangeKind.preferred,
        request: request,
        plan: plan,
        noAlternative: candidates.toList(),
      );
    }

    return _replace(
      kind: PlanChangeKind.swapped,
      request: request,
      plan: plan,
      targets: scoped,
      untouched: const [],
      prefs: effective,
      random: rng,
    );
  }

  /// Tek bir öğünü değiştirir ("Değiştir" butonu).
  PlanChangeOutcome swapMeal({
    required List<PlannedMeal> plan,
    required PlannedMeal meal,
    required MealPlanPreferences prefs,
    Random? random,
  }) => _replace(
    kind: PlanChangeKind.swapped,
    request: PlanChangeRequest(mealTypes: {meal.mealType}),
    plan: plan,
    targets: [meal],
    untouched: const [],
    prefs: prefs,
    random: random ?? Random(),
  );

  PlanChangeOutcome _replace({
    required PlanChangeKind kind,
    required PlanChangeRequest request,
    required List<PlannedMeal> plan,
    required Iterable<PlannedMeal> targets,
    required Iterable<PlannedMeal> untouched,
    required MealPlanPreferences prefs,
    required Random random,
    bool remember = false,
  }) {
    var current = plan;
    final changes = <PlanMealChange>[];
    final failed = <PlannedMeal>[];
    for (final meal in targets.toList()) {
      final alternative = _generator.alternativeFor(
        meal,
        current,
        prefs,
        random: random,
      );
      if (alternative == null) {
        failed.add(meal);
        continue;
      }
      current = _replaceIn(current, {alternative.id: alternative});
      changes.add(PlanMealChange(meal, alternative));
    }
    return PlanChangeOutcome(
      kind: kind,
      request: request,
      plan: current,
      changes: changes,
      noAlternative: failed,
      alreadyMatching: untouched.toList(),
      remember: remember,
    );
  }

  static List<PlannedMeal> _replaceIn(
    List<PlannedMeal> plan,
    Map<String, PlannedMeal> byId,
  ) => [for (final m in plan) byId[m.id] ?? m];
}
