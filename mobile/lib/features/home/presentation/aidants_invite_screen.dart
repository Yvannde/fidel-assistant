import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/aidants_controller.dart';
import 'widgets/home_lottie.dart';

/// Invitation par code sync — zone centrale type écran WA « scanner ».
class AidantsInviteScreen extends ConsumerStatefulWidget {
  const AidantsInviteScreen({super.key});

  @override
  ConsumerState<AidantsInviteScreen> createState() =>
      _AidantsInviteScreenState();
}

class _AidantsInviteScreenState extends ConsumerState<AidantsInviteScreen> {
  String? _code;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code =
          await ref.read(aidantsControllerProvider.notifier).createInviteCode();
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

  Future<void> _copy() async {
    final code = _code;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    AppToast.success(context, AppLocalizations.of(context).homeInviteCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Premium.canvas(tokens.isDark),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(IconsaxPlusLinear.arrow_left),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.homeShareCodeTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: tokens.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.homeInviteHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    height: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
                const Spacer(flex: 2),
                const Center(
                  child: HomeLottie(
                    asset: 'assets/lottie/welcome.json',
                    size: 150,
                    fallbackIcon: IconsaxPlusLinear.user_add,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n.onboardingRetry),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.isDark ? tokens.elevated : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.homeShareCodeBody,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            height: 1.35,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _code ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            height: 1,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                if (!_loading && _error == null && _code != null)
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _copy,
                      icon: const Icon(IconsaxPlusLinear.document_copy, size: 18),
                      label: Text(
                        l10n.homeInviteCopy,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                const Spacer(flex: 3),
                TextButton(
                  onPressed: () => context.push('/home/sync'),
                  child: Text(
                    l10n.homeInviteAltLink,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
