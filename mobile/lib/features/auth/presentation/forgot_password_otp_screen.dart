import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';
import 'widgets/otp_pin_input.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final _pinKey = GlobalKey<OtpPinInputState>();
  bool _busy = false;
  bool _resending = false;
  String? _error;

  Future<void> _onCompleted(String code) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final email = ref.read(forgotPasswordDraftProvider).email;
    if (email == null || email.isEmpty) {
      context.go('/forgot-password');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final token = await ref.read(authRepositoryProvider).verifyOtp(
            email: email,
            code: code,
            type: 'reset_password',
          );
      ref.read(forgotPasswordDraftProvider.notifier).setTempToken(token);
      if (!mounted) return;
      AppToast.success(
        context,
        l10n.successEmailTitle,
        duration: const Duration(milliseconds: 1200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.pushReplacement('/forgot-password/reset');
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
    final email = ref.read(forgotPasswordDraftProvider).email;
    if (email == null) return;

    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendOtp(
            email: email,
            type: 'reset_password',
          );
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
    final email = ref.watch(forgotPasswordDraftProvider).email ?? '';

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
            onCompleted: _onCompleted,
          ),
          if (_error != null) ...[
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
