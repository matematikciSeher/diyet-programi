import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../domain/models/onboarding_step.dart';

/// Hoş geldin ve fayda ekranları.
class IntroStep extends StatelessWidget {
  const IntroStep({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, body) = switch (step) {
      OnboardingStep.benefitPlan => (
        Icons.auto_awesome_outlined,
        l10n.onboardingBenefitPlanTitle,
        l10n.onboardingBenefitPlanBody,
      ),
      OnboardingStep.benefitTracking => (
        Icons.insights_rounded,
        l10n.onboardingBenefitTrackingTitle,
        l10n.onboardingBenefitTrackingBody,
      ),
      OnboardingStep.benefitHabits => (
        Icons.self_improvement_rounded,
        l10n.onboardingBenefitHabitsTitle,
        l10n.onboardingBenefitHabitsBody,
      ),
      _ => (
        Icons.eco_outlined,
        l10n.onboardingWelcomeTitle,
        l10n.onboardingWelcomeBody,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSpacing.gapXxl,
        _IntroIllustration(icon: icon),
        const SizedBox(height: AppSpacing.xxxl),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppSpacing.gapLg,
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        AppSpacing.gapXxl,
        _PageDots(
          count: OnboardingStep.intro.length,
          index: OnboardingStep.intro.indexOf(step),
        ),
      ],
    );
  }
}

class _IntroIllustration extends StatelessWidget {
  const _IntroIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.tertiaryContainer],
          ),
        ),
        child: Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: 0.7),
            ),
            child: Icon(icon, size: 52, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? context.colors.primary
                    : context.colors.outlineVariant,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
