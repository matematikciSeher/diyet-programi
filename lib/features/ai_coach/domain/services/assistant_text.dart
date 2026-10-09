import '../../../../shared/models/enums.dart';

/// Soru metnini niyet kapsamına ayırır. Yanıt üretmez.
enum AssistantQuestionScope {
  swap,
  water,
  activity,
  protein,
  calories,
  meal,
  recipe,
  weekPlan,
  todayPlan,
  weight,
  fasting,
  daily,
  overTarget,
  unknown,
}

abstract final class AssistantText {
  static String normalize(String text) =>
      text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();

  static AssistantQuestionScope scopeOf(String question) {
    final normalized = normalize(question);
    bool any(List<String> words) => words.any(normalized.contains);

    if (any([
      'değiştir',
      'degistir',
      'başka bir şey',
      'swap',
      'replace',
      'change my',
    ])) {
      return AssistantQuestionScope.swap;
    }
    if (any([
      'çok fazla',
      'fazla kalori',
      'fazla yedim',
      'hedefi aştım',
      'hedefimi aştım',
      'fazla kaçırdım',
      'overate',
      'too much',
      'over my',
    ])) {
      return AssistantQuestionScope.overTarget;
    }
    if (any(['adım', 'adim', 'mesafe', 'antrenman', 'workout', 'steps'])) {
      return AssistantQuestionScope.activity;
    }
    if (any(['su hedef', 'su iç', 'su ict', 'ne kadar su', 'water'])) {
      return AssistantQuestionScope.water;
    }
    if (any(['oruç', 'oruc', 'fasting'])) {
      return AssistantQuestionScope.fasting;
    }
    if (any(['kilo', 'ölçü', 'olcu', 'bel ', 'weight'])) {
      return AssistantQuestionScope.weight;
    }
    if (any([
      'bu hafta',
      'haftalık',
      'haftalik',
      'this week',
    ])) {
      return AssistantQuestionScope.weekPlan;
    }
    if (any([
      'ne yiyebilirim',
      'ne yesem',
      'ne yiyeyim',
      'yemek öner',
      'öğün öner',
      'ogun oner',
      'düşük kalori',
      'dusuk kalori',
      'protein ağırlıklı',
      'protein agirlikli',
      'what can i eat',
      'what should i eat',
    ])) {
      return AssistantQuestionScope.meal;
    }
    if (any([
      'tarif',
      'malzeme',
      'evde',
      'recipe',
    ])) {
      return AssistantQuestionScope.recipe;
    }
    if (any([
      'planım',
      'planimi',
      'planımı',
      'bugünkü plan',
      'bugunku plan',
      'neden öner',
      'neden oner',
      'plana uygun',
    ])) {
      return AssistantQuestionScope.todayPlan;
    }
    if (any(['protein'])) return AssistantQuestionScope.protein;
    if (any(['kalori', 'kcal', 'calorie'])) {
      return AssistantQuestionScope.calories;
    }
    if (any([
      'bugün nasıl',
      'bugun nasil',
      'nasıl beslen',
      'nasil beslen',
      'how am i eating',
    ])) {
      return AssistantQuestionScope.daily;
    }
    return AssistantQuestionScope.unknown;
  }

  static MealType? mealTypeIn(String question) {
    final normalized = normalize(question);
    if (normalized.contains('kahvaltı') || normalized.contains('breakfast')) {
      return MealType.breakfast;
    }
    if (normalized.contains('öğle') || normalized.contains('lunch')) {
      return MealType.lunch;
    }
    if (normalized.contains('akşam') || normalized.contains('dinner')) {
      return MealType.dinner;
    }
    if (normalized.contains('atıştır') ||
        normalized.contains('ara öğün') ||
        normalized.contains('snack')) {
      return MealType.snack;
    }
    return null;
  }
}
