import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/media/media_permission_gateway.dart';
import '../../../../shared/services/media/photo_picker_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_log_draft.dart';
import '../../domain/services/food_capture_codes.dart';
import '../../domain/services/food_match_service.dart';
import '../providers/estimated_food_providers.dart';
import '../providers/food_providers.dart';
import '../widgets/food_capture_review.dart';
import '../widgets/food_picker_sheet.dart';

/// Fotoğraf adayları onaylanmadan günlüğe yazılmaz.
class PhotoLogPage extends ConsumerStatefulWidget {
  const PhotoLogPage({
    super.key,
    this.initialMeal,
    this.lockMeal = false,
    this.logDate,
  });

  final MealType? initialMeal;
  final bool lockMeal;
  final DateTime? logDate;

  @override
  ConsumerState<PhotoLogPage> createState() => _PhotoLogPageState();
}

class _PhotoLogPageState extends ConsumerState<PhotoLogPage> {
  FoodCapturePhase? _phase;
  Failure? _failure;
  List<FoodLogDraft> _drafts = const [];
  MealType? _meal;
  var _busy = false;
  var _saving = false;
  var _permissionDenied = false;
  var _generation = 0;
  String? _submissionId;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  Future<void> _pick(PhotoSource source) async {
    if (_busy || _saving) return;
    final gateway = ref.read(mediaPermissionGatewayProvider);
    final access = source == PhotoSource.camera
        ? await gateway.requestCamera()
        : await gateway.requestPhotos();
    if (!mounted) return;
    if (access != MediaAccess.granted) {
      setState(() {
        _permissionDenied = true;
        _failure = foodCaptureFailure(FoodCaptureCodes.permissionDenied);
      });
      return;
    }
    setState(() {
      _busy = true;
      _permissionDenied = false;
      _failure = null;
    });
    try {
      final photo = await ref.read(foodPhotoPickerProvider).pick(source);
      if (!mounted || photo == null) return;
      await _analyze(photo.bytes);
    } on PermissionException {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _failure = foodCaptureFailure(FoodCaptureCodes.permissionDenied);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze(Uint8List bytes) async {
    final generation = ++_generation;
    setState(() => _phase = FoodCapturePhase.uploading);
    final result = await ref
        .read(foodCaptureActionsProvider)
        .analyzePhoto(
          bytes,
          profile: ref.read(userProfileProvider).value,
          locale: Localizations.localeOf(context).toLanguageTag(),
          requestId: 'photo-$generation',
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
          _failure = value.isEmpty
              ? foodCaptureFailure(FoodCaptureCodes.emptyResponse)
              : null;
          _submissionId = 'photo-$generation';
          _phase = FoodCapturePhase.ready;
        });
      case Err(:final failure):
        setState(() {
          _failure = failure;
          _drafts = const [];
          _phase = null;
        });
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
      ref
          .read(foodDraftBuilderProvider)
          .applyMatch(
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
      ref
          .read(foodDraftBuilderProvider)
          .relink(draft, food, profile: ref.read(userProfileProvider).value),
    );
  }

  Future<void> _addFood() async {
    final picked = await pickIngredient(context);
    if (picked == null || !mounted) return;
    final (food, selection) = picked;
    final grams = ref
        .read(foodCalculationServiceProvider)
        .gramsFor(food, selection);
    final draft = ref
        .read(foodDraftBuilderProvider)
        .relink(
          FoodLogDraft(
            localId: 'add-${food.id}-${_drafts.length}',
            queryName: food.name,
            matchStatus: FoodMatchStatus.matched,
            quantity: selection.quantity,
            unit: selection.portion.unit,
            source: FoodSource.aiPhoto,
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
    final result = await ref
        .read(confirmCapturedFoodsProvider)
        .call(
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
    final reviewing = _drafts.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.featurePhotoLog)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          ResponsiveCenter(
            child: reviewing
                ? FoodCaptureReview(
                    drafts: _drafts,
                    meal: _meal,
                    lockMeal: widget.lockMeal,
                    saving: _saving,
                    calculator: ref.watch(foodCalculationServiceProvider),
                    onMeal: (meal) => setState(() => _meal = meal),
                    onChanged: _replace,
                    onSelectFood: (draft, food) => _replace(
                      ref
                          .read(foodDraftBuilderProvider)
                          .relink(
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
                  )
                : _Picker(
                    busy: _busy,
                    phase: _phase,
                    failure: _failure,
                    permissionDenied: _permissionDenied,
                    onCamera: () => _pick(PhotoSource.camera),
                    onGallery: () => _pick(PhotoSource.gallery),
                    onSettings: () =>
                        ref.read(mediaPermissionGatewayProvider).openSettings(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.busy,
    required this.phase,
    required this.failure,
    required this.permissionDenied,
    required this.onCamera,
    required this.onGallery,
    required this.onSettings,
  });

  final bool busy;
  final FoodCapturePhase? phase;
  final Failure? failure;
  final bool permissionDenied;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = switch (phase) {
      FoodCapturePhase.uploading => l10n.photoLogUploading,
      FoodCapturePhase.analyzing => l10n.photoLogAnalyzing,
      FoodCapturePhase.matching => l10n.photoLogMatching,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.photoLogPick, style: context.textStyles.titleMedium),
        AppSpacing.gapLg,
        Semantics(
          button: true,
          label: l10n.photoLogCameraSemantics,
          child: FilledButton.icon(
            key: const ValueKey('photo-camera'),
            onPressed: busy ? null : onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.photoLogCamera),
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(
                Size(48, AppSizes.minTouchTarget),
              ),
            ),
          ),
        ),
        AppSpacing.gapSm,
        Semantics(
          button: true,
          label: l10n.photoLogGallerySemantics,
          child: OutlinedButton.icon(
            key: const ValueKey('photo-gallery'),
            onPressed: busy ? null : onGallery,
            icon: const Icon(Icons.photo_outlined),
            label: Text(l10n.photoLogGallery),
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(
                Size(48, AppSizes.minTouchTarget),
              ),
            ),
          ),
        ),
        if (busy) ...[
          AppSpacing.gapLg,
          const Center(child: CircularProgressIndicator()),
          if (status != null) ...[
            AppSpacing.gapSm,
            Semantics(
              liveRegion: true,
              child: Text(status, textAlign: TextAlign.center),
            ),
          ],
        ],
        if (failure != null) ...[
          AppSpacing.gapLg,
          Text(failure!.localizedMessage(context)),
          if (permissionDenied) ...[
            AppSpacing.gapSm,
            OutlinedButton(
              onPressed: onSettings,
              child: Text(l10n.barcodeOpenSettings),
            ),
          ],
        ],
        AppSpacing.gapLg,
        Text(
          l10n.photoLogDisclaimer,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
