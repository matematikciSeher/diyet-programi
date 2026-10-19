import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/catalog/assistant_catalog.dart';
import '../../domain/models/assistant_grounded_facts.dart';
import '../../domain/models/assistant_reply.dart';
import '../assistant_destinations.dart';
import '../assistant_reply_text.dart';
import '../providers/assistant_providers.dart';
import '../widgets/assistant_browse.dart';

/// Beslenme Asistanı: kullanıcının profil, günlük, su, kilo, ölçüm, plan
/// ve oruç verisine göre yanıt verir. Tıbbi tavsiye vermez.
class AiCoachPage extends ConsumerStatefulWidget {
  const AiCoachPage({super.key});

  @override
  ConsumerState<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends ConsumerState<AiCoachPage> {
  final _scroll = ScrollController();
  final _catalogScroll = ScrollController();
  final _search = TextEditingController();
  final _input = TextEditingController();
  final _categoryKeys = <String, GlobalKey>{};
  var _browse = true;
  var _query = '';

  @override
  void dispose() {
    _scroll.dispose();
    _catalogScroll.dispose();
    _search.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final value = _input.text.trim();
    if (value.isEmpty || ref.read(assistantChatProvider).busy) return;
    _input.clear();
    ref.read(assistantChatProvider.notifier).send(value);
    setState(() => _browse = false);
    _scrollToEnd();
  }

  Future<void> _openQuestion(AssistantQuestion question) async {
    final categoryId = AssistantCatalog.categoryOf(question.id)?.id;
    if (categoryId != null) {
      await ref.read(assistantChatProvider.notifier).openCategory(categoryId);
    }
    if (!mounted) return;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';
    ref.read(assistantChatProvider.notifier).send(
      turkish ? question.tr : question.en,
      questionId: question.id,
    );
    setState(() => _browse = false);
    _scrollToEnd();
  }

  GlobalKey _categoryKey(String id) =>
      _categoryKeys.putIfAbsent(id, GlobalKey.new);

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
    ref.listen(assistantChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) _scrollToEnd();
      final restored =
          (previous == null || !previous.historyReady) &&
          next.historyReady &&
          next.messages.isNotEmpty;
      if (restored && _browse) {
        setState(() => _browse = false);
      }
    });
    final category = AssistantCatalog.categoryById(chat.categoryId ?? '');
    final turkish = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.featureAiCoach),
        actions: [
          if (!_browse || chat.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.assistantBrowseTopics,
              icon: Icon(_browse ? Icons.forum_outlined : Icons.grid_view_outlined),
              onPressed: () {
                setState(() => _browse = !_browse);
                if (_browse) ref.invalidate(assistantTodayProvider);
              },
            ),
          IconButton(
            tooltip: l10n.assistantPrivacyTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPrivacy(context),
          ),
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.assistantClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: chat.busy ? null : () => _confirmClear(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !chat.historyReady
                ? const Center(child: CircularProgressIndicator())
                : _browse
                ? ResponsiveCenter(
                    child: AssistantBrowse(
                      query: _query,
                      scrollController: _catalogScroll,
                      searchController: _search,
                      categoryKey: _categoryKey,
                      onQuery: (value) {
                        setState(() => _query = value);
                        if (_catalogScroll.hasClients) _catalogScroll.jumpTo(0);
                      },
                      onOpenQuestion: (question) => unawaited(_openQuestion(question)),
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    children: [
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (category != null) ...[
                              Text(
                                turkish ? category.titleTr : category.titleEn,
                                key: const ValueKey('assistant-chat-category'),
                                style: context.textStyles.titleMedium,
                              ),
                              AppSpacing.gapXs,
                              Text(
                                turkish
                                    ? category.descriptionTr
                                    : category.descriptionEn,
                                key: const ValueKey('assistant-chat-description'),
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.gapLg,
                            ],
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
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
                    if (chat.historyReady)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('assistant-input'),
                              controller: _input,
                              enabled: !chat.busy,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: l10n.assistantHint,
                                isDense: true,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          FilledButton(
                            key: const ValueKey('assistant-send'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52),
                            ),
                            onPressed: chat.busy ? null : _send,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded, size: 18),
                                AppSpacing.gapXs,
                                Text(l10n.assistantSend),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (chat.historyReady) AppSpacing.gapXs,
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

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assistantClearTitle),
        content: Text(l10n.assistantClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.assistantClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(assistantChatProvider.notifier).clear();
    if (!mounted) return;
    setState(() => _browse = true);
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

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message});

  final AssistantMessage message;

  static (String, IconData) _action(BuildContext context, AssistantAction a) {
    final l10n = context.l10n;
    return switch (a) {
      AssistantAction.openPlan => (
        l10n.assistantOpenPlan,
        Icons.calendar_month_outlined,
      ),
      AssistantAction.openDiary => (l10n.assistantOpenDiary, Icons.book_outlined),
      AssistantAction.openWeight => (
        l10n.assistantOpenWeight,
        Icons.monitor_weight_outlined,
      ),
      AssistantAction.openFasting => (
        l10n.assistantOpenFasting,
        Icons.timer_outlined,
      ),
      AssistantAction.openRecipes => (
        l10n.assistantOpenRecipes,
        Icons.soup_kitchen_outlined,
      ),
      AssistantAction.openWater => (
        l10n.assistantOpenWater,
        Icons.water_drop_outlined,
      ),
      AssistantAction.openShopping => (
        l10n.assistantOpenShopping,
        Icons.shopping_basket_outlined,
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (text, isUser, actions, safety, retryQuestion, recipes, choices) = switch (message) {
      AssistantUserMessage(:final text) => (
        text,
        true,
        const <AssistantAction>[],
        false,
        null,
        const <AssistantRecipeRef>[],
        const <ClarificationChoice>[],
      ),
      AssistantBotMessage(:final reply) => (
        AssistantReplyText.of(context, reply),
        false,
        AssistantDestinations.visible(reply.actions),
        reply is SafetyReply,
        reply is AssistantFailureReply && reply.canRetry ? reply.question : null,
        reply is InterpretedReply
            ? reply.recipes
            : reply is GuideReply
            ? reply.recipes
            : const <AssistantRecipeRef>[],
        reply is ClarificationReply ? reply.choices : const <ClarificationChoice>[],
      ),
      AssistantErrorMessage(:final code, :final question) => (
        AssistantReplyText.failureText(l10n, code),
        false,
        const <AssistantAction>[],
        false,
        question,
        const <AssistantRecipeRef>[],
        const <ClarificationChoice>[],
      ),
    };
    final busy = ref.watch(assistantChatProvider).busy;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';

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
                if (choices.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final choice in choices)
                        Semantics(
                          button: true,
                          label: turkish ? choice.promptTr : choice.promptEn,
                          child: ActionChip(
                            key: ValueKey(
                              'assistant-choice-${choice.questionId ?? choice.labelTr}',
                            ),
                            label: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width - 96,
                              ),
                              child: Text(
                                turkish ? choice.labelTr : choice.labelEn,
                                softWrap: true,
                              ),
                            ),
                            onPressed: busy
                                ? null
                                : () => ref
                                      .read(assistantChatProvider.notifier)
                                      .send(
                                        turkish ? choice.promptTr : choice.promptEn,
                                        questionId: choice.questionId,
                                      ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final a in actions)
                        if (AssistantDestinations.routeOf(a) case final route?)
                          Semantics(
                            button: true,
                            label: _action(context, a).$1,
                            child: ActionChip(
                              key: ValueKey('assistant-action-${a.name}'),
                              avatar: Icon(_action(context, a).$2, size: 18),
                              label: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.sizeOf(context).width - 120,
                                ),
                                child: Text(
                                  _action(context, a).$1,
                                  softWrap: true,
                                ),
                              ),
                              onPressed: () => context.push(route),
                            ),
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
