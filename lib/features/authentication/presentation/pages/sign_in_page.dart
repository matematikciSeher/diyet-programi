import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// E-posta, Google, Apple ve misafir girişi. Firebase yoksa sahte auth
/// aynı arayüzle çalışır.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  static const guestButtonKey = ValueKey('sign-in-guest');
  static const emailSubmitKey = ValueKey('sign-in-email');
  static const googleButtonKey = ValueKey('sign-in-google');

  /// Apple ile giriş bu sürümde yapılandırılmadığı için kapalıdır.
  /// Entitlement, Firebase Apple provider ve credential yoktur; altyapı durur.
  static bool get appleSignInAvailable => false;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  var _isSignUp = false;
  var _obscure = true;
  String? _busy;

  bool get _isBusy => _busy != null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _showApple =>
      SignInPage.appleSignInAvailable &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _handle(Result<Object?> result, {String? successMessage}) async {
    if (!mounted) return;
    result.when(
      success: (_) {
        if (successMessage != null) context.showSnack(successMessage);
      },
      failure: (failure) {
        if (failure is AuthFailure &&
            (failure.code == 'aborted' || failure.message == 'cancelled')) {
          return;
        }
        context.showSnack(failure.localizedMessage(context));
      },
    );
  }

  Future<void> _run(
    String key,
    Future<Result<Object?>> Function() action, {
    String? successMessage,
  }) async {
    setState(() => _busy = key);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = null);
    await _handle(result, successMessage: successMessage);
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    final password = _password.text;
    if (_isSignUp) {
      await _run(
        'email',
        () => repo.signUpWithEmail(
          email,
          password,
          displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        ),
      );
    } else {
      await _run('email', () => repo.signInWithEmail(email, password));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      context.showSnack(context.l10n.authInvalidEmail);
      return;
    }
    await _run(
      'reset',
      () => ref.read(authRepositoryProvider).sendPasswordReset(email),
      successMessage: context.l10n.passwordResetSent,
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@')) {
      return context.l10n.authInvalidEmail;
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.authInvalidCredentials;
    }
    if (_isSignUp && value.length < 6) {
      return context.l10n.authWeakPassword;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ResponsiveCenter(
            maxWidth: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapXl,
                Text(
                  l10n.signInTitle,
                  style: context.textStyles.headlineMedium,
                ),
                AppSpacing.gapMd,
                Text(
                  l10n.signInSubtitle,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapXxl,
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        AppTextField(
                          controller: _name,
                          label: l10n.signInNameLabel,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          enabled: !_isBusy,
                        ),
                        AppSpacing.gapLg,
                      ],
                      AppTextField(
                        controller: _email,
                        label: l10n.signInEmailLabel,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: _emailValidator,
                        enabled: !_isBusy,
                      ),
                      AppSpacing.gapLg,
                      AppTextField(
                        controller: _password,
                        label: l10n.signInPasswordLabel,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: _isSignUp
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        validator: _passwordValidator,
                        enabled: !_isBusy,
                        onSubmitted: (_) => _submitEmail(),
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton.text(
                            label: l10n.actionForgotPassword,
                            onPressed: _isBusy ? null : _forgotPassword,
                          ),
                        ),
                      AppSpacing.gapMd,
                      KeyedSubtree(
                        key: SignInPage.emailSubmitKey,
                        child: AppButton(
                          label: _isSignUp
                              ? l10n.actionSignUp
                              : l10n.actionSignIn,
                          isLoading: _busy == 'email',
                          onPressed: _isBusy ? null : _submitEmail,
                        ),
                      ),
                      AppButton.text(
                        label: _isSignUp
                            ? l10n.actionHaveAccount
                            : l10n.actionNeedAccount,
                        onPressed: _isBusy
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapXl,
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(l10n.signInOrDivider),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                AppSpacing.gapXl,
                KeyedSubtree(
                  key: SignInPage.googleButtonKey,
                  child: AppButton.secondary(
                    label: l10n.actionSignInWithGoogle,
                    icon: Icons.g_mobiledata_rounded,
                    isLoading: _busy == 'google',
                    onPressed: _isBusy
                        ? null
                        : () => _run(
                            'google',
                            () => ref
                                .read(authRepositoryProvider)
                                .signInWithGoogle(),
                          ),
                  ),
                ),
                if (_showApple) ...[
                  AppSpacing.gapMd,
                  AppButton.secondary(
                    label: l10n.actionSignInWithApple,
                    icon: Icons.apple,
                    isLoading: _busy == 'apple',
                    onPressed: _isBusy
                        ? null
                        : () => _run(
                            'apple',
                            () => ref
                                .read(authRepositoryProvider)
                                .signInWithApple(),
                          ),
                  ),
                ],
                AppSpacing.gapLg,
                KeyedSubtree(
                  key: SignInPage.guestButtonKey,
                  child: AppButton.text(
                    label: l10n.actionContinueAsGuest,
                    isLoading: _busy == 'guest',
                    expand: true,
                    onPressed: _isBusy
                        ? null
                        : () => _run(
                            'guest',
                            () => ref
                                .read(authRepositoryProvider)
                                .continueAsGuest(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
