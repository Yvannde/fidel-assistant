import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends ConsumerState<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(
            email: _emailCtrl.text,
          );
      ref.read(forgotPasswordDraftProvider.notifier).setEmail(_emailCtrl.text);
      if (!mounted) return;
      AppToast.success(context, l10n.forgotOtpSent);
      context.push('/forgot-password/otp');
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

    return AuthShell(
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            TextFormField(
              controller: _emailCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                hintText: l10n.emailHint,
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return l10n.fieldRequired;
                if (!value.contains('@') || !value.contains('.')) {
                  return l10n.invalidEmail;
                }
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
                  : Text(l10n.forgotContinue),
            ),
          ],
        ),
      ),
    );
  }
}
