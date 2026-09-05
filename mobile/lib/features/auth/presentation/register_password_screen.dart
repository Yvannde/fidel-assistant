import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

class RegisterPasswordScreen extends ConsumerStatefulWidget {
  const RegisterPasswordScreen({super.key});

  @override
  ConsumerState<RegisterPasswordScreen> createState() =>
      _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState
    extends ConsumerState<RegisterPasswordScreen> {
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
    final draft = ref.read(registrationDraftProvider);
    final tempToken = draft.tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      context.go('/register');
      return;
    }

    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).setPassword(
            tempToken: tempToken,
            password: _passwordCtrl.text,
          );
      ref
          .read(registrationDraftProvider.notifier)
          .setPassword(_passwordCtrl.text);
      if (!mounted) return;
      context.push('/register/legal');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
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
      title: l10n.passwordTitle,
      subtitle: l10n.passwordSubtitle,
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
                  : Text(l10n.passwordContinue),
            ),
          ],
        ),
      ),
    );
  }
}
