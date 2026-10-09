import 'package:flutter/material.dart';

import '../errors/failure_messages.dart';
import '../errors/failures.dart';
import '../theme/app_spacing.dart';
import '../utils/extensions/context_extensions.dart';
import 'app_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            AppSpacing.gapLg,
            Text(message!, style: context.textStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Bilgilendirici boş/hata/yakında durumları için ortak iskelet.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Icon(
                    icon,
                    size: AppSizes.iconLg,
                    color: context.colors.onSecondaryContainer,
                  ),
                ),
              ),
              AppSpacing.gapLg,
              Text(
                title,
                style: context.textStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                AppSpacing.gapSm,
                Text(
                  message!,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                AppSpacing.gapXl,
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: icon,
      title: title ?? context.l10n.emptyStateTitle,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final message = failure is Failure
        ? failure.localizedMessage(context)
        : context.l10n.errorGeneric;
    return MessageView(
      icon: Icons.error_outline_rounded,
      title: message,
      actionLabel: onRetry == null ? null : context.l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
