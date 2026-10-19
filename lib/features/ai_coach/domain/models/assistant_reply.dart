import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import 'assistant_grounded_facts.dart';
import 'guide_snapshot.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

/// Yanıtın altında gösterilen kısayollar.
enum AssistantAction {
  openPlan,
  openDiary,
  openWeight,
  openFasting,
  openRecipes,
  openWater,
  openShopping,
}

/// Asistan yanıtları yapılandırılmış döner; metin arayüzde yerelleştirilir.
/// Böylece aynı yanıt Türkçe/İngilizce gösterilebilir ve test edilebilir.
sealed class AssistantReply extends Equatable {
  const AssistantReply({
    this.actions = const [],
    this.commentary,
    this.commentarySuppressed = false,
  });

  final List<AssistantAction> actions;

  /// Modelin yorumu. Sayılar buradan okunmaz; kayıtlar ayrı hesaplanır.
  final String? commentary;

  /// Alerji açısından güvenli olmayan yorum gösterilmez.
  final bool commentarySuppressed;
}

final class RemainingCaloriesReply extends AssistantReply {
  const RemainingCaloriesReply({
    required this.consumed,
    required this.target,
    super.actions = const [AssistantAction.openDiary],
  });

  final double consumed;
  final double target;

  double get remaining => target - consumed;

  @override
  List<Object?> get props => [consumed, target];
}

final class ProteinStatusReply extends AssistantReply {
  const ProteinStatusReply({
    required this.consumed,
    required this.target,
    super.actions = const [AssistantAction.openRecipes],
  });

  final double consumed;
  final double target;

  bool get reached => consumed >= target;
  double get remaining => target - consumed;

  @override
  List<Object?> get props => [consumed, target];
}

final class MealSuggestionReply extends AssistantReply {
  const MealSuggestionReply({
    required this.mealType,
    required this.remainingCalories,
    required this.suggestions,
    this.fromPlan,
    super.actions = const [AssistantAction.openPlan, AssistantAction.openRecipes],
  });

  final MealType mealType;
  final double remainingCalories;

  /// Plandaki, henüz yenmemiş öğün.
  final PlannedMeal? fromPlan;

  /// Kalan kaloriye ve kısıtlara uyan alternatifler.
  final List<PlannedMeal> suggestions;

  bool get isLight => remainingCalories < 300;

  @override
  List<Object?> get props => [mealType, remainingCalories, fromPlan, suggestions];
}

final class SwapPlanReply extends AssistantReply {
  const SwapPlanReply({
    this.meal,
    super.actions = const [AssistantAction.openPlan],
  });

  /// Sorudan anlaşılan ya da sıradaki plan öğünü.
  final PlannedMeal? meal;

  @override
  List<Object?> get props => [meal];
}

final class OverTargetReply extends AssistantReply {
  const OverTargetReply({
    required this.overCalories,
    super.actions = const [AssistantAction.openDiary],
  });

  /// Hedefin üzerindeki kalori; hedef aşılmadıysa 0 veya negatif.
  final double overCalories;

  @override
  List<Object?> get props => [overCalories];
}

final class WaterStatusReply extends AssistantReply {
  const WaterStatusReply({
    required this.consumedMl,
    required this.goalMl,
    super.actions = const [AssistantAction.openWater],
  });

  final int consumedMl;
  final int goalMl;

  @override
  List<Object?> get props => [consumedMl, goalMl];
}

final class WeightProgressReply extends AssistantReply {
  const WeightProgressReply({
    this.startKg,
    this.currentKg,
    this.targetKg,
    this.latestWaistCm,
    super.actions = const [AssistantAction.openWeight],
  });

  final double? startKg;
  final double? currentKg;
  final double? targetKg;
  final double? latestWaistCm;

  @override
  List<Object?> get props => [startKg, currentKg, targetKg, latestWaistCm];
}

final class FastingStatusReply extends AssistantReply {
  const FastingStatusReply({
    this.phase,
    this.remaining,
    super.actions = const [AssistantAction.openFasting],
  });

  /// `null`: oruç protokolü seçilmemiş.
  final FastingPhase? phase;
  final Duration? remaining;

  @override
  List<Object?> get props => [phase, remaining];
}

enum SafetyConcern { medical, eatingDisorder, extremeRestriction, emergency }

/// Tıbbi, yeme bozukluğu veya aşırı kısıtlama içeren sorularda yanıt
/// verilmez; bir sağlık profesyoneline yönlendirilir.
final class SafetyReply extends AssistantReply {
  const SafetyReply(this.concern);

  final SafetyConcern concern;

  @override
  List<Object?> get props => [concern];
}

final class HelpReply extends AssistantReply {
  const HelpReply();

  @override
  List<Object?> get props => const [];
}

/// Belirsiz soruda kullanıcının seçeceği katalog konusu.
class ClarificationChoice extends Equatable {
  const ClarificationChoice({
    required this.labelTr,
    required this.labelEn,
    required this.promptTr,
    required this.promptEn,
    this.questionId,
  });

  final String? questionId;
  final String labelTr;
  final String labelEn;
  final String promptTr;
  final String promptEn;

  @override
  List<Object?> get props => [questionId, labelTr, labelEn, promptTr, promptEn];
}

/// Birden fazla konu gerçekten uygunsa kısa bir seçim.
final class ClarificationReply extends AssistantReply {
  const ClarificationReply({required this.choices});

  final List<ClarificationChoice> choices;

  @override
  List<Object?> get props => [choices];
}

/// Soru konu taşımıyorsa kısa bir açıklama istenir.
final class DetailRequestReply extends AssistantReply {
  const DetailRequestReply();

  @override
  List<Object?> get props => const [];
}

enum TrackedMacro { carbs, fat }

/// Protein dışındaki kayıtlı makro. Değerler günlük kayıttan gelir.
final class MacroStatusReply extends AssistantReply {
  const MacroStatusReply({
    required this.macro,
    required this.consumed,
    required this.target,
    super.actions = const [AssistantAction.openDiary],
  });

  final TrackedMacro macro;
  final double consumed;
  final double target;

  bool get reached => consumed >= target;
  double get remaining => target - consumed;

  @override
  List<Object?> get props => [macro, consumed, target];
}

enum DailyNutritionHint { onTrack, proteinShort, overCalories }

/// Bugünkü kayıtların özeti. Makro alanları yalnızca kayıtta değer varsa dolu sayılır.
final class DailyNutritionReply extends AssistantReply {
  const DailyNutritionReply({
    required this.mealCount,
    required this.consumedCalories,
    required this.targetCalories,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
    required this.macrosRecorded,
    required this.hint,
    required this.targetBelowSafeFloor,
    super.actions = const [AssistantAction.openDiary],
  });

  final int mealCount;
  final double consumedCalories;
  final double targetCalories;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final bool macrosRecorded;
  final DailyNutritionHint hint;

  /// Kayıtlı hedef güvenli alt sınırın altındaysa daha düşüğü önerilmez.
  final bool targetBelowSafeFloor;

  @override
  List<Object?> get props => [
    mealCount,
    consumedCalories,
    targetCalories,
    proteinConsumed,
    proteinTarget,
    carbsConsumed,
    carbsTarget,
    fatConsumed,
    fatTarget,
    macrosRecorded,
    hint,
    targetBelowSafeFloor,
  ];
}

enum MissingRecord { meals, macros, plan }

/// Kayıt yokken tahmin yerine açık bir eksik-veri yanıtı.
final class MissingRecordReply extends AssistantReply {
  const MissingRecordReply(
    this.record, {
    super.actions = const [AssistantAction.openDiary],
  });

  final MissingRecord record;

  @override
  List<Object?> get props => [record, actions];
}

/// Bugün için kayıtlı plan öğünleri. Listede olmayan öğün eklenmez.
final class PlanStatusReply extends AssistantReply {
  const PlanStatusReply({
    required this.meals,
    super.actions = const [AssistantAction.openPlan],
  });

  final List<PlannedMeal> meals;

  @override
  List<Object?> get props => [meals];
}

/// Release'te proxy adresi yokken sahte yanıt yerine dönen durum.
final class UnavailableAssistantReply extends AssistantReply {
  const UnavailableAssistantReply({
    this.code = AssistantErrorCodes.notConfigured,
  });

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Ağ, zaman aşımı, kota veya bozuk yanıt. Uygulama verisi uydurulmaz.
final class AssistantFailureReply extends AssistantReply {
  const AssistantFailureReply({required this.code, this.question = ''});

  final String code;
  final String question;

  bool get canRetry =>
      code != AssistantErrorCodes.emptyMessage &&
      code != AssistantErrorCodes.notConfigured &&
      code != AssistantErrorCodes.messageTooLong;

  @override
  List<Object?> get props => [code, question];
}

/// Uygulamanın hesapladığı kayıtlar ve doğrulanmış tarifler.
/// Model yalnızca [commentary] ile yorum yapar.
final class InterpretedReply extends AssistantReply {
  const InterpretedReply({
    required this.facts,
    this.recipes = const [],
    super.commentary,
    super.commentarySuppressed,
    super.actions = const [],
  });

  final AssistantGroundedFacts facts;
  final List<AssistantRecipeRef> recipes;

  @override
  List<Object?> get props => [facts, recipes, commentary, commentarySuppressed, actions];
}

/// Katalog sorusunun cevabı. Metin yereldeki rehberden, sayılar
/// [snapshot] içindeki kayıtlardan okunur.
final class GuideReply extends AssistantReply {
  const GuideReply({
    required this.questionId,
    this.snapshot = const GuideSnapshot(),
    this.recipes = const [],
    this.disclaimer = false,
    super.actions = const [],
  });

  final String questionId;
  final GuideSnapshot snapshot;
  final List<AssistantRecipeRef> recipes;
  final bool disclaimer;

  @override
  List<Object?> get props => [questionId, snapshot, recipes, disclaimer, actions];
}

abstract final class AssistantErrorCodes {
  static const notConfigured = 'AI_SERVICE_NOT_CONFIGURED';
  static const premiumRequired = 'premium_required';
  static const timeout = 'timeout';
  static const offline = 'no_connection';
  static const rateLimited = 'rate_limited';
  static const invalidResponse = 'invalid_response';
  static const emptyResponse = 'empty_response';
  static const unavailable = 'unavailable';
  static const malformed = 'malformed_response';
  static const emptyMessage = 'empty_message';
  static const duplicate = 'duplicate_request';
  static const messageTooLong = 'message_too_long';
}
