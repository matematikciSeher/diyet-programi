import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';
import 'nutrition_assistant_service.dart';

/// Premium kapısı ekranın yanında servis çağrısında da durur.
class PremiumAwareNutritionAssistant implements NutritionAssistantService {
  const PremiumAwareNutritionAssistant({
    required NutritionAssistantService inner,
    required this.allowed,
  }) : _inner = inner;

  final NutritionAssistantService _inner;
  final bool Function() allowed;

  @override
  Future<AssistantReply> reply(
    String question,
    AssistantContext context,
  ) async {
    if (!allowed()) {
      return const UnavailableAssistantReply(
        code: AssistantErrorCodes.premiumRequired,
      );
    }
    return _inner.reply(question, context);
  }
}
