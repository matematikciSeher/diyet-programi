import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/nutrition/nutrition_calculator.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../authentication/data/repositories/auth_repository_impl.dart';
import '../../data/repositories/local_onboarding_repository.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/models/onboarding_step.dart';
import '../../domain/onboarding_validator.dart';
import 'onboarding_controller.dart';

class OnboardingFlowState extends Equatable {
  const OnboardingFlowState({
    required this.draft,
    this.showErrors = false,
    this.isSubmitting = false,
    this.isForward = true,
    this.submitFailure,
  });

  final OnboardingDraft draft;

  /// Kullanıcı geçersiz bir adımda "İleri"ye bastıysa hatalar gösterilir.
  final bool showErrors;
  final bool isSubmitting;

  /// Geçiş animasyonunun yönü.
  final bool isForward;
  final Failure? submitFailure;

  OnboardingStep get step => draft.currentStep;
  List<OnboardingStep> get flow => draft.flow;

  List<OnboardingStep> get questions =>
      flow.where((s) => s.isQuestion).toList(growable: false);

  /// 1'den başlayan soru sırası; soru dışı adımlarda `null`.
  int? get questionNumber {
    final i = questions.indexOf(step);
    return i < 0 ? null : i + 1;
  }

  double get progress {
    if (step.isIntro) return 0;
    if (step == OnboardingStep.summary) return 1;
    return (questionNumber ?? 0) / (questions.length + 1);
  }

  OnboardingValidationError? get error =>
      OnboardingValidator.validate(step, draft);

  OnboardingValidationError? get visibleError => showErrors ? error : null;

  bool get canGoBack => flow.indexOf(step) > 0;

  OnboardingFlowState copyWith({
    OnboardingDraft? draft,
    bool? showErrors,
    bool? isSubmitting,
    bool? isForward,
    Failure? submitFailure,
    bool clearFailure = false,
  }) {
    return OnboardingFlowState(
      draft: draft ?? this.draft,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isForward: isForward ?? this.isForward,
      submitFailure: clearFailure ? null : submitFailure ?? this.submitFailure,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    showErrors,
    isSubmitting,
    isForward,
    submitFailure,
  ];
}

/// Onboarding adımlarını, doğrulamayı, taslağın saklanmasını ve
/// tamamlanınca profilin oluşturulmasını yönetir.
class OnboardingFlowController extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() {
    final saved = ref.read(onboardingRepositoryProvider).readDraft();
    var draft = saved ?? const OnboardingDraft();
    if (!draft.flow.contains(draft.currentStep)) {
      draft = draft.copyWith(currentStep: OnboardingStep.welcome);
    }
    if (draft.currentStep == OnboardingStep.summary) {
      final invalid = OnboardingValidator.firstInvalidStep(draft);
      if (invalid != null) draft = draft.copyWith(currentStep: invalid);
    }
    return OnboardingFlowState(draft: draft);
  }

  void update(OnboardingDraft Function(OnboardingDraft draft) change) {
    final draft = change(state.draft);
    if (draft == state.draft) return;
    state = state.copyWith(draft: draft);
    _persist();
  }

  /// Geçerliyse sonraki adıma geçer; değilse hataları gösterir ve `false`
  /// döner.
  bool next() {
    if (state.isSubmitting) return false;
    if (state.error != null) {
      state = state.copyWith(showErrors: true);
      return false;
    }
    final flow = state.flow;
    final index = flow.indexOf(state.step);
    if (index < 0 || index >= flow.length - 1) return false;

    var target = flow[index + 1];
    if (target == OnboardingStep.summary) {
      target = OnboardingValidator.firstInvalidStep(state.draft) ?? target;
    }
    _goTo(target, forward: true);
    return true;
  }

  void back() {
    final flow = state.flow;
    final index = flow.indexOf(state.step);
    if (index <= 0 || state.isSubmitting) return;
    _goTo(flow[index - 1], forward: false);
  }

  /// Tanıtım ekranlarını geçip ilk soruya atlar.
  void skipIntro() {
    if (!state.step.isIntro) return;
    _goTo(state.questions.first, forward: true);
  }

  void _goTo(OnboardingStep step, {required bool forward}) {
    state = state.copyWith(
      draft: state.draft.copyWith(currentStep: step),
      showErrors: false,
      isForward: forward,
      clearFailure: true,
    );
    _persist();
  }

  void _persist() {
    unawaited(ref.read(onboardingRepositoryProvider).saveDraft(state.draft));
  }

  /// Profili oluşturur, kaydeder ve onboarding'i tamamlar. Başarılıysa
  /// yönlendirme router tarafından yapılır.
  Future<bool> complete() async {
    if (state.isSubmitting) return false;
    final input = state.draft.toNutritionInput();
    final invalid = OnboardingValidator.firstInvalidStep(state.draft);
    if (input == null || invalid != null) {
      _goTo(invalid ?? OnboardingStep.goal, forward: false);
      state = state.copyWith(showErrors: true);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final plan = ref.read(nutritionCalculatorProvider).calculate(input);

    var uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      final signIn = await ref.read(authRepositoryProvider).continueAsGuest();
      if (!ref.mounted) return false;
      final failure = signIn.failureOrNull;
      if (failure != null) return _fail(failure);
      uid = signIn.valueOrNull!.uid;
    }

    final profile = state.draft.toProfile(
      id: uid,
      plan: plan,
      now: DateTime.now(),
    );
    final saved = await ref
        .read(userProfileRepositoryProvider)
        .saveProfile(profile);
    if (!ref.mounted) return false;
    final failure = saved.failureOrNull;
    if (failure != null) return _fail(failure);

    await ref.read(onboardingRepositoryProvider).clearDraft();
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (ref.mounted) state = state.copyWith(isSubmitting: false);
    return true;
  }

  bool _fail(Failure failure) {
    state = state.copyWith(isSubmitting: false, submitFailure: failure);
    return false;
  }
}

final onboardingFlowProvider =
    NotifierProvider.autoDispose<OnboardingFlowController, OnboardingFlowState>(
      OnboardingFlowController.new,
    );

/// Mevcut cevaplarla hesaplanan plan; eksik bilgi varsa `null`.
final onboardingPlanProvider = Provider.autoDispose<NutritionPlan?>((ref) {
  final input = ref.watch(
    onboardingFlowProvider.select((s) => s.draft.toNutritionInput()),
  );
  if (input == null) return null;
  return ref.watch(nutritionCalculatorProvider).calculate(input);
});
