import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

class ForgotPasswordResetScreen extends ConsumerStatefulWidget {
  const ForgotPasswordResetScreen({super.key});

  @override
  ConsumerState<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends ConsumerState<ForgotPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(forgotPasswordDraftProvider);
    final email = draft.email;
    final code = draft.code;
    if (email == null || code == null) {
      context.go('/forgot-password');
      return;
    }

    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: email,
            code: code,
            nouveauPassword: _passwordCtrl.text,
          );
      ref.read(forgotPasswordDraftProvider.notifier).reset();
      if (!mounted) return;
      AppToast.success(context, l10n.forgotResetSuccess);
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
      AppToast.error(context, l10n.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minLen = AppConfig.passwordMinLength;

    return AuthShell(
      title: l10n.forgotResetTitle,
      subtitle: l10n.forgotResetSubtitle,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            TextFormField(
              controller: _passwordCtrl,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                hintText: l10n.passwordHint,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return l10n.fieldRequired;
                if ((v ?? '').length < minLen) {
                  return l10n.passwordTooShort(minLen);
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmCtrl,
              enabled: !_busy,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.confirmPasswordLabel,
                hintText: l10n.passwordHint,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return l10n.fieldRequired;
                if (v != _passwordCtrl.text) return l10n.passwordMismatch;
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.forgotResetCta),
            ),
          ],
        ),
      ),
    );
  }
}
