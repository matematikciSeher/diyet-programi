import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import 'assistant_grounded_facts.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

/// Yanıtın altında gösterilen kısayollar.
enum AssistantAction { openPlan, openDiary, openWeight, openFasting, openRecipes }

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
    super.actions = const [AssistantAction.openPlan],
  });

  /// Hedefin üzerindeki kalori; hedef aşılmadıysa 0 veya negatif.
  final double overCalories;

  @override
  List<Object?> get props => [overCalories];
}

final class WaterStatusReply extends AssistantReply {
  const WaterStatusReply({required this.consumedMl, required this.goalMl});

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

enum SafetyConcern { medical, eatingDisorder, extremeRestriction }

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

abstract final class AssistantErrorCodes {
  static const notConfigured = 'AI_SERVICE_NOT_CONFIGURED';
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
