import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'auth_navigation.dart';
import 'widgets/auth_shell.dart';
import 'widgets/google_sign_in_button.dart';

const _rememberEmailKey = 'fa_remember_email';
const _savedEmailKey = 'fa_saved_email';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  final VoidCallback onLoggedIn;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final remember = prefs.getBool(_rememberEmailKey) ?? true;
    final email = prefs.getString(_savedEmailKey) ?? '';
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (email.isNotEmpty) _emailCtrl.text = email;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authSessionProvider.notifier).login(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_rememberEmailKey, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(_savedEmailKey, _emailCtrl.text.trim());
      } else {
        await prefs.remove(_savedEmailKey);
      }
      if (!mounted) return;
      widget.onLoggedIn();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message.isNotEmpty ? e.message : l10n.loginFailed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.loginFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final langue =
          ref.read(localeControllerProvider)?.languageCode ?? 'fr';
      final session = await ref.read(authSessionProvider.notifier).loginWithGoogle(
            langue: langue,
            fuseauHoraire: 'Africa/Douala',
          );
      if (!mounted) return;
      navigateAfterAuth(context, session);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'GOOGLE_CANCELLED') {
        AppToast.info(context, l10n.googleCancelled);
      } else if (e.code == 'GOOGLE_NOT_CONFIGURED') {
        AppToast.info(context, l10n.googleNotConfigured);
      } else {
        setState(() => _error = e.message);
        AppToast.error(context, e.message.isNotEmpty ? e.message : l10n.googleFailed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.googleFailed);
      AppToast.error(context, l10n.googleFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AuthShell(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            GoogleSignInButton(
              label: l10n.continueWithGoogle,
              busy: _busy,
              onPressed: _busy ? null : _google,
            ),
            const SizedBox(height: 22),
            _OrDivider(label: l10n.orLoginWith),
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                hintText: l10n.emailHint,
                labelText: l10n.emailLabel,
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
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l10n.passwordHint,
                labelText: l10n.passwordLabel,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
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
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _busy
                        ? null
                        : () => setState(() => _rememberMe = !_rememberMe),
                    child: Text(
                      l10n.rememberMe,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : widget.onForgotPassword,
                  child: Text(l10n.forgotPassword),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                  : Text(l10n.logIn),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.noAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : widget.onSignUp,
                  child: Text(l10n.signUp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
