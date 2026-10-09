import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/models/onboarding_step.dart';
import '../providers/onboarding_flow_controller.dart';
import '../widgets/intro_step.dart';
import '../widgets/question_steps.dart';
import '../widgets/summary_step.dart';

/// Kişiselleştirme akışı: tanıtım ekranları, tek soruluk adımlar ve sonuç.
/// Tüm adımlar tek sayfada yönetilir; ilerleme her değişiklikte saklanır.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  static const _contentMaxWidth = 560.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);

    ref.listen(onboardingFlowProvider.select((s) => s.submitFailure), (
      _,
      failure,
    ) {
      if (failure != null) context.showSnack(failure.localizedMessage(context));
    });

    return PopScope(
      canPop: !state.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) {
                      final incoming = child.key == ValueKey(state.step);
                      final dx = incoming == state.isForward ? 0.08 : -0.08;
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: Offset(dx, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _StepScrollView(
                      key: ValueKey(state.step),
                      step: state.step,
                    ),
                  ),
                ),
                _BottomBar(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepScrollView extends StatelessWidget {
  const _StepScrollView({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (step) {
      _ when step.isIntro => IntroStep(step: step),
      OnboardingStep.summary => const SummaryStep(),
      _ => QuestionStep(step: step),
    };
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
      child: ResponsiveCenter(
        maxWidth: OnboardingPage._contentMaxWidth,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: content,
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state});

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final step = state.step;

    final Widget child;
    if (step.isIntro) {
      child = Align(
        alignment: AlignmentDirectional.centerEnd,
        child: step == OnboardingStep.welcome
            ? const SizedBox(height: AppSizes.minTouchTarget)
            : TextButton(
                onPressed: ref.read(onboardingFlowProvider.notifier).skipIntro,
                child: Text(l10n.onboardingSkipIntro),
              ),
      );
    } else {
      final total = state.questions.length;
      final current = state.questionNumber ?? total;
      child = Row(
        children: [
          Expanded(
            child: Semantics(
              label: l10n.onboardingProgressSemantics(current, total),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: state.progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                  child: LinearProgressIndicator(value: value, minHeight: 6),
                ),
              ),
            ),
          ),
          AppSpacing.gapMd,
          ExcludeSemantics(
            child: Text(
              l10n.onboardingStepCounter(current, total),
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
    }

    return ResponsiveCenter(
      maxWidth: OnboardingPage._contentMaxWidth,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SizedBox(height: AppSizes.minTouchTarget, child: child),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state});

  final OnboardingFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(onboardingFlowProvider.notifier);
    final step = state.step;
    final isSummary = step == OnboardingStep.summary;

    final primaryLabel = switch (step) {
      OnboardingStep.welcome => l10n.actionGetStarted,
      OnboardingStep.summary => l10n.onboardingFinish,
      _ => l10n.onboardingNext,
    };

    void onPrimary() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (isSummary) {
        controller.complete();
      } else {
        controller.next();
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: ResponsiveCenter(
        maxWidth: OnboardingPage._contentMaxWidth,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (state.canGoBack) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
                onPressed: state.isSubmitting ? null : controller.back,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.onboardingBack),
              ),
              AppSpacing.gapMd,
            ],
            Expanded(
              child: AppButton(
                key: const ValueKey('onboarding-primary'),
                label: primaryLabel,
                isLoading: state.isSubmitting,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
