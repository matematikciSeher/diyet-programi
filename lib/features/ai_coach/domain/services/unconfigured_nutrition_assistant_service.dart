import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';
import 'assistant_safety.dart';
import 'assistant_text.dart';
import 'nutrition_assistant_service.dart';

/// Proxy adresi yokken kullanılan asistan.
///
/// Sahte beslenme yorumu üretmez. Güvenlik kapısı yine çalışır.
class UnconfiguredNutritionAssistantService implements NutritionAssistantService {
  const UnconfiguredNutritionAssistantService();

  @override
  Future<AssistantReply> reply(String question, AssistantContext context) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantFailureReply(code: AssistantErrorCodes.emptyMessage);
    }
    if (trimmed.length > 2000) {
      return AssistantFailureReply(
        code: AssistantErrorCodes.messageTooLong,
        question: trimmed,
      );
    }
    final concern = AssistantSafety.check(AssistantText.normalize(trimmed));
    if (concern != null) return SafetyReply(concern);
    return const UnavailableAssistantReply();
  }
}
