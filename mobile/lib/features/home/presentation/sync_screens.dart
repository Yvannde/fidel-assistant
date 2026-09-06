import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

class SyncAidantScreen extends ConsumerStatefulWidget {
  const SyncAidantScreen({super.key});

  @override
  ConsumerState<SyncAidantScreen> createState() => _SyncAidantScreenState();
}

class _SyncAidantScreenState extends ConsumerState<SyncAidantScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_code.text.trim().length < 4) {
      AppToast.error(context, l10n.fieldRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      final msg = await ref
          .read(homeControllerProvider.notifier)
          .joinWithCode(_code.text);
      if (!mounted) return;
      AppToast.success(context, msg.isEmpty ? l10n.homeSyncOk : msg);
      context.go('/home');
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
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.homeAccompanyTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.homeSyncHint,
                style: TextStyle(color: ThemeTokens.of(context).textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.homeSyncCodeLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(l10n.homeSyncCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShareCodeScreen extends ConsumerStatefulWidget {
  const ShareCodeScreen({super.key});

  @override
  ConsumerState<ShareCodeScreen> createState() => _ShareCodeScreenState();
}

class _ShareCodeScreenState extends ConsumerState<ShareCodeScreen> {
  String? _code;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final code =
          await ref.read(homeControllerProvider.notifier).createShareCode();
      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException
            ? e.message
            : AppLocalizations.of(context).genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.homeShareCodeTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Text(_error!)
                    : PremiumCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.homeShareCodeBody,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ThemeTokens.of(context).textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _code ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 6,
                                  ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
