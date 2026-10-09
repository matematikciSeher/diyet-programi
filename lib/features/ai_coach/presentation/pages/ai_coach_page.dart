import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../domain/models/assistant_grounded_facts.dart';
import '../../domain/models/assistant_reply.dart';
import '../assistant_reply_text.dart';
import '../providers/assistant_providers.dart';

/// Beslenme Asistanı: kullanıcının profil, günlük, su, kilo, ölçüm, plan
/// ve oruç verisine göre yanıt verir. Tıbbi tavsiye vermez.
class AiCoachPage extends ConsumerStatefulWidget {
  const AiCoachPage({super.key});

  @override
  ConsumerState<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends ConsumerState<AiCoachPage> {
  final _scroll = ScrollController();
  final _input = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    ref.read(assistantChatProvider.notifier).send(value);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chat = ref.watch(assistantChatProvider);
    final profile = ref.watch(userProfileProvider).value;
    ref.listen(
      assistantChatProvider.select((s) => s.messages.length),
      (_, _) => _scrollToEnd(),
    );
    final suggestions = assistantQuickPrompts(l10n, profile?.goal);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.featureAiCoach),
        actions: [
          IconButton(
            tooltip: l10n.assistantPrivacyTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPrivacy(context),
          ),
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.assistantClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: chat.busy
                  ? null
                  : () => ref.read(assistantChatProvider.notifier).clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !chat.historyReady
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                ? EmptyStateView(
                    icon: Icons.auto_awesome_outlined,
                    title: l10n.assistantEmptyTitle,
                    message: l10n.assistantEmptyMessage,
                  )
                : ListView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    children: [
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final m in chat.messages) ...[
                              _Bubble(message: m),
                              AppSpacing.gapMd,
                            ],
                            if (chat.busy)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Semantics(
                                    label: l10n.assistantThinking,
                                    child: const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Material(
            color: context.colors.surfaceContainer,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, _) => AppSpacing.gapSm,
                        itemBuilder: (context, i) => ActionChip(
                          label: Text(suggestions[i]),
                          onPressed: chat.busy
                              ? null
                              : () => _send(suggestions[i]),
                        ),
                      ),
                    ),
                    AppSpacing.gapSm,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('assistant-input'),
                            controller: _input,
                            enabled: !chat.busy,
                            textInputAction: TextInputAction.send,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: l10n.assistantHint,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: l10n.planChangeSend,
                          onPressed: chat.busy ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                    AppSpacing.gapXs,
                    Text(
                      l10n.assistantDisclaimer,
                      textAlign: TextAlign.center,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    final l10n = context.l10n;
    unawaited(showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assistantPrivacyTitle),
        content: SingleChildScrollView(child: Text(l10n.assistantPrivacyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    ));
  }
}

List<String> assistantQuickPrompts(AppLocalizations l10n, GoalType? goal) {
  final dinner = switch (goal) {
    GoalType.loseWeight => l10n.assistantQuickDinnerLose,
    GoalType.buildMuscle || GoalType.gainWeight =>
      l10n.assistantQuickProteinMeal,
    _ => l10n.assistantQuickDinner,
  };
  return [
    l10n.assistantQuickToday,
    dinner,
    l10n.assistantQuickProteinBoost,
    l10n.assistantQuickWaterGoal,
    l10n.assistantQuickPlanReview,
    l10n.assistantQuickRecipe,
  ];
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message});

  final AssistantMessage message;

  static (String, IconData) _action(BuildContext context, AssistantAction a) {
    final l10n = context.l10n;
    return switch (a) {
      AssistantAction.openPlan => (
        l10n.featureNutrition,
        Icons.calendar_month_outlined,
      ),
      AssistantAction.openDiary => (l10n.navDiary, Icons.book_outlined),
      AssistantAction.openWeight => (
        l10n.featureWeight,
        Icons.monitor_weight_outlined,
      ),
      AssistantAction.openFasting => (l10n.featureFasting, Icons.timer_outlined),
      AssistantAction.openRecipes => (
        l10n.featureRecipes,
        Icons.soup_kitchen_outlined,
      ),
    };
  }

  static String _route(AssistantAction a) => switch (a) {
    AssistantAction.openPlan => AppRoutes.nutritionPlan,
    AssistantAction.openDiary => AppRoutes.diary,
    AssistantAction.openWeight => AppRoutes.weight,
    AssistantAction.openFasting => AppRoutes.fasting,
    AssistantAction.openRecipes => AppRoutes.recipes,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (text, isUser, actions, safety, retryQuestion, recipes) = switch (message) {
      AssistantUserMessage(:final text) => (
        text,
        true,
        const <AssistantAction>[],
        false,
        null,
        const <AssistantRecipeRef>[],
      ),
      AssistantBotMessage(:final reply) => (
        AssistantReplyText.of(context, reply),
        false,
        reply.actions,
        reply is SafetyReply,
        reply is AssistantFailureReply && reply.canRetry ? reply.question : null,
        reply is InterpretedReply ? reply.recipes : const <AssistantRecipeRef>[],
      ),
      AssistantErrorMessage(:final code, :final question) => (
        AssistantReplyText.failureText(l10n, code),
        false,
        const <AssistantAction>[],
        false,
        question,
        const <AssistantRecipeRef>[],
      ),
    };

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser
                ? colors.primaryContainer
                : safety
                ? colors.tertiaryContainer
                : colors.surfaceContainerHigh,
            borderRadius: AppRadius.lgAll,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        safety
                            ? Icons.health_and_safety_outlined
                            : Icons.auto_awesome_rounded,
                        size: AppSizes.iconSm,
                        color: colors.primary,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        l10n.featureAiCoach,
                        style: context.textStyles.labelMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXs,
                ],
                Text(
                  text,
                  softWrap: true,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: isUser ? colors.onPrimaryContainer : null,
                  ),
                ),
                if (recipes.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final recipe in recipes)
                        ActionChip(
                          avatar: const Icon(Icons.soup_kitchen_outlined, size: 18),
                          label: Text(recipe.title),
                          onPressed: () => context.push(
                            AppRoutes.recipeDetailPath(recipe.id),
                          ),
                        ),
                    ],
                  ),
                ],
                if (retryQuestion != null && retryQuestion.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => ref
                          .read(assistantChatProvider.notifier)
                          .retry(retryQuestion),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.assistantRetry),
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final a in actions)
                        ActionChip(
                          avatar: Icon(_action(context, a).$2, size: 18),
                          label: Text(_action(context, a).$1),
                          onPressed: () => context.push(_route(a)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
