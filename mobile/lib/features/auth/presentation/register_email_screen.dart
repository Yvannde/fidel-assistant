import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

class RegisterEmailScreen extends ConsumerStatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  ConsumerState<RegisterEmailScreen> createState() =>
      _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends ConsumerState<RegisterEmailScreen> {
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
      final locale =
          ref.read(localeControllerProvider)?.languageCode ?? 'fr';
      await ref.read(authRepositoryProvider).register(
            email: _emailCtrl.text,
            langue: locale,
            fuseauHoraire: 'Africa/Douala',
          );
      ref.read(registrationDraftProvider.notifier).setEmail(_emailCtrl.text);
      if (!mounted) return;
      context.push('/register/otp');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_ALREADY_VERIFIED') {
        setState(() => _error = l10n.emailAlreadyVerified);
      } else {
        setState(() => _error = e.message);
      }
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
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
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
                  : Text(l10n.registerContinue),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.haveAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.go('/login'),
                  child: Text(l10n.logIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
