import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/food.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../domain/models/portion_selection.dart';
import 'food_format.dart';
import 'providers/food_providers.dart';

/// Yiyeceği öğüne ekler ve geri alınabilir bir bildirim gösterir.
/// [day] verilirse kayıt o güne eklenir. Başarılıysa `true` döner.
Future<bool> logFoodWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required Food food,
  required PortionSelection selection,
  required MealType meal,
  DateTime? day,
}) async {
  final logFood = ref.read(logFoodProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  unawaited(HapticFeedback.lightImpact());

  final result = await logFood(
    food: food,
    selection: selection,
    mealType: meal,
    servingLabel: FoodFormat.selection(context, food, selection),
    day: day,
  );
  final message = result.when(
    success: (_) => l10n.foodAddedTo(food.name, meal.label(l10n)),
    failure: (f) => context.mounted ? f.localizedMessage(context) : null,
  );
  final entry = result.valueOrNull;
  if (message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: entry == null
              ? null
              : SnackBarAction(
                  label: l10n.actionUndo,
                  onPressed: () => logFood.undo(entry.id),
                ),
        ),
      );
  }
  return entry != null;
}
