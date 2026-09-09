import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../application/home_controller.dart';

/// Soft delete — `DELETE /auth/me`.
class ProfileDeleteAccountScreen extends ConsumerStatefulWidget {
  const ProfileDeleteAccountScreen({super.key});

  @override
  ConsumerState<ProfileDeleteAccountScreen> createState() =>
      _ProfileDeleteAccountScreenState();
}

class _ProfileDeleteAccountScreenState
    extends ConsumerState<ProfileDeleteAccountScreen> {
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(homeControllerProvider).profile;
    final needsPassword = profile?.hasPassword == true;

    if (needsPassword && _password.text.isEmpty) {
      AppToast.error(context, l10n.fieldRequired);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.profileDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(homeRepositoryProvider).deleteAccount(
            password: needsPassword ? _password.text : null,
          );
      await ref.read(authSessionProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final needsPassword =
        ref.watch(homeControllerProvider).profile?.hasPassword == true;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
                    title: Text(l10n.profileDeleteTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.profileDeleteHint,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            if (needsPassword) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.profileDeleteAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
