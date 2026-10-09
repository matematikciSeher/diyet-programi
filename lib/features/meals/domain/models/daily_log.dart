import 'package:equatable/equatable.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../activity/domain/models/daily_activity.dart';
import 'daily_nutrition_score.dart';

/// Tek bir öğün (kahvaltı, öğle...) ve içindeki yiyecekler.
class MealLog extends Equatable {
  MealLog({required this.type, List<MealEntry> entries = const []})
    : entries = List.unmodifiable(entries),
      total = entries.fold(NutritionFacts.zero, (sum, e) => sum + e.nutrition);

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
    type: JsonUtils.readEnum(MealType.values, json['type'], MealType.snack),
    entries: JsonUtils.readMapList(
      json['entries'],
    ).map(MealEntry.fromJson).toList(),
  );

  final MealType type;
  final List<MealEntry> entries;

  /// Öğündeki yiyeceklerin toplamı.
  final NutritionFacts total;

  bool get isEmpty => entries.isEmpty;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'entries': [for (final e in entries) e.toJson()],
    'total': total.toJson(),
  };

  @override
  List<Object?> get props => [type, entries];
}

/// Bir günün tüm beslenme kaydı: öğünler, su, aktivite, kilo ve skor.
///
/// Firestore'da `users/{uid}/daily_logs/{yyyy-MM-dd}` özet dökümanı olarak
/// saklanabilecek şekilde tasarlanmıştır; şimdilik ayrı koleksiyonlardan
/// (öğün, su, aktivite, kilo) birleştirilerek oluşturulur.
class DailyLog extends Equatable {
  DailyLog({
    required DateTime date,
    required List<MealLog> meals,
    this.userId,
    List<WaterLog> waterLogs = const [],
    this.activity = DailyActivity.empty,
    this.weight,
    this.nutritionScore,
    this.createdAt,
    this.updatedAt,
  }) : date = date.startOfDay,
       meals = List.unmodifiable(meals),
       waterLogs = List.unmodifiable(waterLogs),
       totals = meals.fold(NutritionFacts.zero, (sum, m) => sum + m.total),
       waterAmount = waterLogs.fold(0, (sum, l) => sum + l.amountMl);

  /// Kayıtları öğün türüne göre gruplar; her öğün her zaman bulunur.
  factory DailyLog.fromEntries({
    required DateTime date,
    required List<MealEntry> entries,
    String? userId,
    List<WaterLog> waterLogs = const [],
    DailyActivity activity = DailyActivity.empty,
    WeightEntry? weight,
  }) {
    final stamps = [
      for (final e in entries) ...[e.loggedAt, ?e.updatedAt],
      for (final w in waterLogs) w.loggedAt,
      ?weight?.recordedAt,
    ]..sort();
    return DailyLog(
      date: date,
      userId: userId,
      meals: [
        for (final type in MealType.values)
          MealLog(
            type: type,
            entries: [
              for (final e in entries)
                if (e.mealType == type) e,
            ],
          ),
      ],
      waterLogs: waterLogs,
      activity: activity,
      weight: weight,
      createdAt: stamps.firstOrNull,
      updatedAt: stamps.lastOrNull,
    );
  }

  factory DailyLog.empty(DateTime date) =>
      DailyLog.fromEntries(date: date, entries: const []);

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    final weight = JsonUtils.readMap(json['weight']);
    final score = JsonUtils.readMap(json['nutritionScore']);
    return DailyLog(
      date: JsonUtils.readDateOr(json['date'], DateTime.now()),
      userId: JsonUtils.readStringOrNull(json['userId']),
      meals: JsonUtils.readMapList(
        json['meals'],
      ).map(MealLog.fromJson).toList(),
      waterLogs: JsonUtils.readMapList(
        json['waterLogs'],
      ).map(WaterLog.fromJson).toList(),
      activity: DailyActivity.fromJson(JsonUtils.readMap(json['activity'])),
      weight: weight.isEmpty ? null : WeightEntry.fromJson(weight),
      nutritionScore: score.isEmpty
          ? null
          : DailyNutritionScore.fromJson(score),
      createdAt: JsonUtils.readDate(json['createdAt']),
      updatedAt: JsonUtils.readDate(json['updatedAt']),
    );
  }

  /// Gün anahtarı (`yyyy-MM-dd`); döküman id'si olarak kullanılır.
  String get id => date.dayKey;
  final String? userId;

  /// Günün başlangıcı (yerel saat).
  final DateTime date;

  /// [MealType.values] sırasıyla.
  final List<MealLog> meals;
  final List<WaterLog> waterLogs;
  final DailyActivity activity;

  /// O gün girilmiş en son kilo kaydı.
  final WeightEntry? weight;
  final DailyNutritionScore? nutritionScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Günün toplam kalori ve makroları.
  final NutritionFacts totals;

  /// Toplam su (ml).
  final int waterAmount;

  List<MealEntry> get entries => [for (final m in meals) ...m.entries];

  bool get isEmpty => meals.every((m) => m.isEmpty);

  MealLog meal(MealType type) => meals.firstWhere(
    (m) => m.type == type,
    orElse: () => MealLog(type: type),
  );

  DailyLog withScore(DailyNutritionScore score) => DailyLog(
    date: date,
    meals: meals,
    userId: userId,
    waterLogs: waterLogs,
    activity: activity,
    weight: weight,
    nutritionScore: score,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'meals': [for (final m in meals) m.toJson()],
    'waterAmount': waterAmount,
    'waterLogs': [for (final w in waterLogs) w.toJson()],
    'activity': activity.toJson(),
    if (weight != null) 'weight': weight!.toJson(),
    if (nutritionScore != null) 'nutritionScore': nutritionScore!.toJson(),
    'totals': totals.toJson(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    date,
    userId,
    meals,
    waterLogs,
    activity,
    weight,
    nutritionScore,
    createdAt,
    updatedAt,
  ];
}
