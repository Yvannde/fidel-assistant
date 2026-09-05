import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

/// CGU / consentement après Google (Bearer, sans temp_token).
class GoogleLegalScreen extends ConsumerStatefulWidget {
  const GoogleLegalScreen({super.key});

  @override
  ConsumerState<GoogleLegalScreen> createState() => _GoogleLegalScreenState();
}

class _GoogleLegalScreenState extends ConsumerState<GoogleLegalScreen> {
  bool _cgu = false;
  bool _consent = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(authSessionProvider);
    if (session == null) {
      context.go('/login');
      return;
    }
    if (!_cgu || !_consent) {
      setState(() => _error = l10n.legalRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (session.needsCgu) {
        await repo.acceptCgu(version: AppConfig.cguCurrentVersion);
      }
      if (session.needsConsentementSante) {
        await repo.acceptConsentementSante();
      }
      ref.read(authSessionProvider.notifier).markLegalAccepted();
      if (!mounted) return;
      if (session.isNewUser || session.onboardingStep != 'termine') {
        context.go('/register/account-success');
      } else {
        context.go('/home');
      }
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
    final version = AppConfig.cguCurrentVersion;

    return AuthShell(
      title: l10n.legalTitle,
      subtitle: l10n.legalSubtitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          _Tile(
            value: _cgu,
            label: l10n.legalCgu(version),
            onChanged: _busy
                ? null
                : (v) => setState(() {
                      _cgu = v ?? false;
                      _error = null;
                    }),
          ),
          const SizedBox(height: 12),
          _Tile(
            value: _consent,
            label: l10n.legalConsent,
            onChanged: _busy
                ? null
                : (v) => setState(() {
                      _consent = v ?? false;
                      _error = null;
                    }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 28),
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
                : Text(l10n.legalFinish),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ThemeTokens.of(context).elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: value, onChanged: onChanged),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
