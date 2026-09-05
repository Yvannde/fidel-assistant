import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';
import 'widgets/otp_pin_input.dart';

class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  final _pinKey = GlobalKey<OtpPinInputState>();
  bool _busy = false;
  bool _resending = false;
  String? _error;

  Future<void> _verify(String code) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(registrationDraftProvider);
    final email = draft.email;
    if (email == null || email.isEmpty) {
      context.go('/register');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final token = await ref.read(authRepositoryProvider).verifyOtp(
            email: email,
            code: code,
          );
      ref.read(registrationDraftProvider.notifier).setTempToken(token);
      if (!mounted) return;
      // Mini succès (toast) puis redirection auto vers le mot de passe.
      AppToast.success(
        context,
        l10n.successEmailTitle,
        duration: const Duration(milliseconds: 1800),
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      context.pushReplacement('/register/password');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _pinKey.currentState?.clear();
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
      _pinKey.currentState?.clear();
      AppToast.error(context, l10n.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final email = ref.read(registrationDraftProvider).email;
    if (email == null) return;

    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendOtp(email: email);
      if (!mounted) return;
      _pinKey.currentState?.clear();
      AppToast.success(context, l10n.otpResent);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
      AppToast.error(context, l10n.genericError);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final email = ref.watch(registrationDraftProvider).email ?? '';

    return AuthShell(
      title: l10n.otpTitle,
      subtitle: l10n.otpSubtitle(email),
      onBack: () => context.pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Text(
            l10n.otpLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OtpPinInput(
            key: _pinKey,
            enabled: !_busy && !_resending,
            hasError: _error != null,
            onCompleted: _verify,
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ],
          if (_error != null && !_busy) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 28),
          TextButton(
            onPressed: (_busy || _resending) ? null : _resend,
            child: _resending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.otpResend),
          ),
        ],
      ),
    );
  }
}
