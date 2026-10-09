import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../core/utils/extensions/date_extensions.dart';
import '../../../shared/models/food.dart';
import '../../../shared/models/meal_entry.dart';
import '../../food/presentation/food_format.dart';

/// Seçili günün bugüne göre konumu; metin seçimlerinde kullanılır.
enum DiaryDayKind {
  past,
  today,
  future;

  static DiaryDayKind of(DateTime day, DateTime today) {
    if (day.isSameDay(today)) return DiaryDayKind.today;
    return day.isBefore(today) ? DiaryDayKind.past : DiaryDayKind.future;
  }
}

abstract final class DiaryFormat {
  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// "28 Eylül"
  static String dayMonth(BuildContext context, DateTime date) =>
      DateFormat.MMMMd(_locale(context)).format(date);

  /// "Pzt"
  static String weekdayShort(BuildContext context, DateTime date) =>
      DateFormat.E(_locale(context)).format(date);

  /// "Bugün", "Dün", "Yarın" ya da gün adı ("Pazartesi").
  static String relativeDay(
    BuildContext context,
    DateTime date,
    DateTime today,
  ) {
    final l10n = context.l10n;
    if (date.isSameDay(today)) return l10n.diaryToday;
    if (date.isSameDay(today.addDays(-1))) return l10n.diaryYesterday;
    if (date.isSameDay(today.addDays(1))) return l10n.diaryTomorrow;
    final weekday = DateFormat.EEEE(_locale(context)).format(date);
    return date.year == today.year ? weekday : '$weekday, ${date.year}';
  }

  /// "2 dilim (50 g)", "3 adet (150 g)" ya da "150 g".
  static String portion(BuildContext context, MealEntry entry) {
    final label = entry.servingLabel;
    if (label != null && label.isNotEmpty) return label;
    final grams = FoodFormat.grams(context, entry.quantityGrams);
    final quantity = entry.quantity;
    final unit = entry.unit;
    if (quantity == null || unit == null || unit.isBaseUnit) {
      return unit == PortionUnit.milliliter
          ? context.l10n.portionQuantity(
              FoodFormat.quantityInput(context, entry.quantityGrams),
              context.l10n.unitMilliliter,
            )
          : grams;
    }
    final l10n = context.l10n;
    return l10n.portionWithBase(
      l10n.portionQuantity(
        FoodFormat.quantityInput(context, quantity),
        unit.label(l10n, quantity),
      ),
      grams,
    );
  }
}
