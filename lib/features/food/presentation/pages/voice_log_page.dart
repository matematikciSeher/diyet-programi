import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/media/media_permission_gateway.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_log_draft.dart';
import '../../domain/services/food_match_service.dart';
import '../../domain/services/spoken_meal_parser.dart';
import '../providers/estimated_food_providers.dart';
import '../providers/food_providers.dart';
import '../widgets/food_capture_review.dart';
import '../widgets/food_picker_sheet.dart';

/// Ses adayları onaylanmadan günlüğe yazılmaz. Kayıt saklanmaz.
class VoiceLogPage extends ConsumerStatefulWidget {
  const VoiceLogPage({super.key, this.initialMeal, this.logDate});

  final MealType? initialMeal;
  final DateTime? logDate;

  @override
  ConsumerState<VoiceLogPage> createState() => _VoiceLogPageState();
}

class _VoiceLogPageState extends ConsumerState<VoiceLogPage> {
  final _text = TextEditingController();
  FoodCapturePhase? _phase;
  List<FoodLogDraft> _drafts = const [];
  MealType? _meal;
  var _listening = false;
  var _saving = false;
  var _parsed = false;
  var _generation = 0;
  String? _submissionId;
  String? _error;
  StreamSubscription<String>? _speech;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  @override
  void dispose() {
    _speech?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_listening) return;
    final access = await ref.read(mediaPermissionGatewayProvider).requestMicrophone();
    if (!mounted) return;
    if (access != MediaAccess.granted) {
      setState(() => _error = context.l10n.errorPermission);
      return;
    }
    final speech = ref.read(speechInputServiceProvider);
    final available = await speech.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _error = context.l10n.captureErrorSpeechUnavailable);
      return;
    }
    setState(() {
      _listening = true;
      _phase = FoodCapturePhase.parsing;
      _error = null;
    });
    final limit = Duration(
      seconds: ref.read(appConfigProvider).effectiveVoiceMaxDurationSeconds,
    );
    _speech = speech
        .listen(localeId: 'tr_TR', listenFor: limit)
        .listen(
          (words) {
            if (!mounted || words.trim().isEmpty) return;
            setState(() => _text.text = words);
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() {
              _listening = false;
              _error = context.l10n.captureErrorTranscription;
              _phase = null;
            });
          },
          onDone: () {
            if (!mounted) return;
            setState(() => _listening = false);
            if (_text.text.trim().isNotEmpty) _parse();
          },
        );
  }

  Future<void> _stop() async {
    await ref.read(speechInputServiceProvider).stop();
    await _speech?.cancel();
    if (!mounted) return;
    setState(() => _listening = false);
    if (_text.text.trim().isNotEmpty) await _parse();
  }

  Future<void> _parse() async {
    final generation = ++_generation;
    setState(() => _phase = FoodCapturePhase.parsing);
    final result = await ref.read(foodCaptureActionsProvider).analyzeTranscript(
      _text.text,
      profile: ref.read(userProfileProvider).value,
      onPhase: (phase) {
        if (!mounted || generation != _generation) return;
        setState(() => _phase = phase);
      },
    );
    if (!mounted || generation != _generation) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _drafts = value;
          _parsed = true;
          _submissionId = 'voice-$generation';
          _phase = FoodCapturePhase.ready;
          _error = null;
        });
      case Err(:final failure):
        setState(() => _error = failure.localizedMessage(context));
    }
  }

  void _replace(FoodLogDraft next) {
    setState(() {
      _drafts = [
        for (final draft in _drafts)
          if (draft.localId == next.localId) next else draft,
      ];
    });
  }

  Future<void> _rematch(FoodLogDraft draft, String query) async {
    final name = query.trim();
    if (name.isEmpty) return;
    final match = await const FoodMatchService().resolve(
      ref.read(foodRepositoryProvider),
      name: name,
    );
    if (!mounted) return;
    _replace(
      ref.read(foodDraftBuilderProvider).applyMatch(
        draft.copyWith(queryName: name),
        match,
        profile: ref.read(userProfileProvider).value,
      ),
    );
  }

  Future<void> _pickReplacement(FoodLogDraft draft) async {
    final food = await pickFood(context);
    if (food == null || !mounted) return;
    _replace(
      ref.read(foodDraftBuilderProvider).relink(
        draft,
        food,
        profile: ref.read(userProfileProvider).value,
      ),
    );
  }

  Future<void> _addFood() async {
    final picked = await pickIngredient(context);
    if (picked == null || !mounted) return;
    final (food, selection) = picked;
    final grams = ref.read(foodCalculationServiceProvider).gramsFor(food, selection);
    final draft = ref.read(foodDraftBuilderProvider).relink(
      FoodLogDraft(
        localId: 'voice-add-${food.id}-${_drafts.length}',
        queryName: food.name,
        matchStatus: FoodMatchStatus.matched,
        quantity: selection.quantity,
        unit: selection.portion.unit,
        source: FoodSource.voice,
        baseAmount: grams ?? selection.baseAmount,
      ),
      food,
      profile: ref.read(userProfileProvider).value,
    );
    setState(() => _drafts = [..._drafts, draft]);
  }

  Future<void> _save() async {
    if (_saving || _submissionId == null || _meal == null) return;
    setState(() => _saving = true);
    final result = await ref.read(confirmCapturedFoodsProvider).call(
      drafts: _drafts,
      mealType: _meal,
      submissionId: _submissionId!,
      day: widget.logDate,
      confirmed: true,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        context.showSnack(context.l10n.photoLogAdded);
        context.pop();
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showSample = ref.watch(appConfigProvider).useFakeServices;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureVoiceLog)),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxxl),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: _listening ? l10n.voiceLogStop : l10n.voiceLogMicSemantics,
                  child: FilledButton.icon(
                    key: const ValueKey('voice-mic'),
                    onPressed: _listening ? _stop : _listen,
                    icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_none_rounded),
                    label: Text(_listening ? l10n.voiceLogStop : l10n.voiceLogMic),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(
                        Size(48, AppSizes.minTouchTarget),
                      ),
                    ),
                  ),
                ),
                if (_listening || _phase == FoodCapturePhase.matching) ...[
                  AppSpacing.gapSm,
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _listening ? l10n.voiceLogListening : l10n.photoLogMatching,
                    ),
                  ),
                ],
                AppSpacing.gapLg,
                AppTextField(
                  controller: _text,
                  label: l10n.voiceLogTranscript,
                  hint: l10n.voiceLogHint,
                  maxLines: 3,
                ),
                AppSpacing.gapSm,
                Text(
                  l10n.voiceLogDisclaimer,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (showSample)
                      OutlinedButton(
                        key: const ValueKey('voice-sample'),
                        onPressed: () {
                          _text.text = SpokenMealParser.samplePhrase;
                          _parse();
                        },
                        child: Text(l10n.voiceLogSimulate),
                      ),
                    FilledButton.tonal(
                      key: const ValueKey('voice-parse'),
                      onPressed: _parse,
                      child: Text(l10n.voiceLogParse),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  AppSpacing.gapMd,
                  Text(_error!),
                ],
                if (_parsed) ...[
                  AppSpacing.gapLg,
                  if (_drafts.isEmpty)
                    Text(l10n.voiceLogEmpty)
                  else
                    FoodCaptureReview(
                      drafts: _drafts,
                      meal: _meal,
                      saving: _saving,
                      calculator: ref.watch(foodCalculationServiceProvider),
                      onMeal: (meal) => setState(() => _meal = meal),
                      onChanged: _replace,
                      onSelectFood: (draft, food) => _replace(
                        ref.read(foodDraftBuilderProvider).relink(
                          draft,
                          food,
                          profile: ref.read(userProfileProvider).value,
                        ),
                      ),
                      onRemove: (draft) => setState(
                        () => _drafts = [
                          for (final item in _drafts)
                            if (item.localId != draft.localId) item,
                        ],
                      ),
                      onRematch: _rematch,
                      onPickReplacement: _pickReplacement,
                      onAddFood: _addFood,
                      onCreateCustom: () => context.push(
                        AppRoutes.customFoodPath(
                          meal: _meal,
                          date: widget.logDate,
                        ),
                      ),
                      onSave: _save,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
