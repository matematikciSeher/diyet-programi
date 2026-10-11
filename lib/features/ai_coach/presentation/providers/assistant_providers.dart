import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/domain/premium_access.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../recipes/data/repositories/recipe_repository_impl.dart';
import '../../data/assistant_chat_store.dart';
import '../../data/repositories/assistant_context_repository_impl.dart';
import '../../domain/models/assistant_context.dart';
import '../../domain/models/assistant_reply.dart';
import '../../domain/services/assistant_service_selector.dart';
import '../../domain/services/mock_nutrition_assistant_service.dart';
import '../../domain/services/nutrition_assistant_service.dart';
import '../../domain/services/premium_nutrition_assistant.dart';

final nutritionAssistantServiceProvider = Provider<NutritionAssistantService>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  final inner = selectNutritionAssistantService(
    config: config,
    fake: MockNutritionAssistantService(ref.watch(mealPlanGeneratorProvider)),
    ai: ref.watch(aiNutritionServiceProvider),
    loadRecipes: (profile) =>
        ref.read(recipeRepositoryProvider).getRecommendedRecipes(profile),
    loadWeek: (day) =>
        ref.read(mealPlanRepositoryProvider).watchWeek(day).first,
  );
  return PremiumAwareNutritionAssistant(
    inner: inner,
    allowed: () => canAccessFeature(
      ref.read(subscriptionStatusProvider).asData?.value,
      AppFeature.aiCoach,
    ),
  );
});

final assistantTodayProvider = FutureProvider<AssistantContext>(
  (ref) => ref.watch(assistantContextRepositoryProvider).snapshot(),
);

final assistantChatStoreProvider = Provider<AssistantChatStore>(
  (ref) => AssistantChatStore(ref.watch(localDocumentDatabaseProvider)),
);

sealed class AssistantMessage extends Equatable {
  const AssistantMessage();
}

final class AssistantUserMessage extends AssistantMessage {
  const AssistantUserMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class AssistantBotMessage extends AssistantMessage {
  const AssistantBotMessage(this.reply);

  final AssistantReply reply;

  @override
  List<Object?> get props => [reply];
}

final class AssistantErrorMessage extends AssistantMessage {
  const AssistantErrorMessage({
    this.code = AssistantErrorCodes.unavailable,
    this.question = '',
  });

  final String code;
  final String question;

  @override
  List<Object?> get props => [code, question];
}

class AssistantChatState extends Equatable {
  const AssistantChatState({
    this.messages = const [],
    this.busy = false,
    this.historyReady = false,
  });

  final List<AssistantMessage> messages;
  final bool busy;
  final bool historyReady;

  AssistantChatState copyWith({
    List<AssistantMessage>? messages,
    bool? busy,
    bool? historyReady,
  }) => AssistantChatState(
    messages: messages ?? this.messages,
    busy: busy ?? this.busy,
    historyReady: historyReady ?? this.historyReady,
  );

  @override
  List<Object?> get props => [messages, busy, historyReady];
}

/// Sohbet cihazdaki belge veritabanında durur. Firebase kuyruğuna yazılmaz.
class AssistantChatController extends Notifier<AssistantChatState> {
  late final Future<void> ready;
  int _epoch = 0;

  @override
  AssistantChatState build() {
    ready = _restore();
    return const AssistantChatState();
  }

  Future<void> _restore() async {
    final loaded = await ref.read(assistantChatStoreProvider).load();
    if (!ref.mounted) return;
    state = AssistantChatState(
      messages: [for (final item in loaded) ?_messageOf(item)],
      historyReady: true,
    );
  }

  Future<void> send(String text) async {
    await ready;
    final question = text.trim();
    if (question.isEmpty || state.busy) return;
    if (!_hasPremium()) return;
    final messages = [...state.messages, AssistantUserMessage(question)];
    final epoch = _epoch;
    state = state.copyWith(messages: messages, busy: true);
    if (epoch != _epoch || !ref.mounted) return;
    await _persist(messages);
    await _complete(question, messages, epoch);
  }

  Future<void> retry(String question) async {
    await ready;
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.busy) return;
    if (!_hasPremium()) return;
    final messages = [...state.messages];
    if (messages.isNotEmpty && _isRetryable(messages.last)) {
      messages.removeLast();
    }
    final epoch = _epoch;
    state = state.copyWith(messages: messages, busy: true);
    await _complete(trimmed, messages, epoch);
  }

  Future<void> clear() async {
    await ready;
    _epoch++;
    state = const AssistantChatState(historyReady: true);
    await ref.read(assistantChatStoreProvider).replaceAll(const []);
  }

  bool _hasPremium() => canAccessFeature(
    ref.read(subscriptionStatusProvider).asData?.value,
    AppFeature.aiCoach,
  );

  Future<void> _complete(
    String question,
    List<AssistantMessage> base,
    int epoch,
  ) async {
    AssistantMessage answer;
    try {
      final context = await ref
          .read(assistantContextRepositoryProvider)
          .snapshot();
      final reply = await ref
          .read(nutritionAssistantServiceProvider)
          .reply(question, context);
      answer = AssistantBotMessage(reply);
    } on Object {
      answer = AssistantErrorMessage(
        code: AssistantErrorCodes.unavailable,
        question: question,
      );
    }
    if (!ref.mounted || epoch != _epoch) return;
    final messages = [...base, answer];
    state = state.copyWith(messages: messages, busy: false, historyReady: true);
    if (!ref.mounted || epoch != _epoch) return;
    await _persist(messages);
  }

  Future<void> _persist(List<AssistantMessage> messages) async {
    await ref.read(assistantChatStoreProvider).replaceAll([
      for (final message in messages) ?_transcriptOf(message),
    ]);
  }

  bool _isRetryable(AssistantMessage message) => switch (message) {
    AssistantErrorMessage() => true,
    AssistantBotMessage(:final reply) =>
      reply is AssistantFailureReply && reply.canRetry,
    _ => false,
  };

  AssistantMessage? _messageOf(AssistantTranscript item) => switch (item.role) {
    'user' => AssistantUserMessage(item.text ?? ''),
    'assistant' when item.reply != null => AssistantBotMessage(item.reply!),
    'error' => AssistantErrorMessage(
      code: item.code ?? AssistantErrorCodes.unavailable,
      question: item.question ?? '',
    ),
    _ => null,
  };

  AssistantTranscript? _transcriptOf(AssistantMessage message) =>
      switch (message) {
        AssistantUserMessage(:final text) => AssistantTranscript.user(text),
        AssistantBotMessage(:final reply) => AssistantTranscript.assistant(
          reply,
        ),
        AssistantErrorMessage(:final code, :final question) =>
          AssistantTranscript.error(code: code, question: question),
      };
}

final assistantChatProvider =
    NotifierProvider<AssistantChatController, AssistantChatState>(
      AssistantChatController.new,
    );
