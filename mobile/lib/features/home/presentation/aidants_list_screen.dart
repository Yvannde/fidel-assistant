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
import '../domain/aidant_models.dart';
import 'widgets/aidants_empty_state.dart';
import 'widgets/home_lottie.dart';
import 'widgets/home_skeleton.dart';

/// Liste des aidants liés — structure type « appareils connectés ».
class AidantsListScreen extends ConsumerStatefulWidget {
  const AidantsListScreen({super.key});

  @override
  ConsumerState<AidantsListScreen> createState() => _AidantsListScreenState();
}

class _AidantsListScreenState extends ConsumerState<AidantsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aidantsControllerProvider.notifier).load();
    });
  }

  String _permSubtitle(AppLocalizations l10n, AidantPermissions p) {
    if (p.observance && p.constantes) return l10n.homeAidantsPermBoth;
    if (p.observance) return l10n.homeAidantsPermObservanceOnly;
    if (p.constantes) return l10n.homeAidantsPermConstantes;
    return l10n.homeAidantsPermNone;
  }

  Future<void> _openManage(AidantRelation aidant) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AidantManageSheet(aidantId: aidant.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(aidantsControllerProvider);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Premium.canvas(tokens.isDark),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(IconsaxPlusLinear.arrow_left),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.homeAidantsTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: tokens.textPrimary,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(aidantsControllerProvider.notifier).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
            children: [
              const Center(
                child: HomeLottie(
                  asset: 'assets/lottie/care_self.json',
                  size: 180,
                  fallbackIcon: IconsaxPlusLinear.people,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.homeAidantsIntro,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.4,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.push('/home/aidants/invite'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    l10n.homeAidantsInviteCta,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.homeAidantsSection.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeAidantsSectionHint,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.35,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (state.loading && state.aidants.isEmpty)
                const ProfileListSkeleton(count: 3)
              else if (state.error != null && state.aidants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                )
              else if (state.aidants.isEmpty)
                AidantsEmptyState(
                  onInvite: () => context.push('/home/aidants/invite'),
                )
              else
                for (final a in state.aidants) ...[
                  _AidantTile(
                    aidant: a,
                    subtitle: _permSubtitle(l10n, a.permissions),
                    onTap: () => _openManage(a),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    IconsaxPlusLinear.lock_1,
                    size: 16,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          height: 1.4,
                          color: tokens.textSecondary,
                        ),
                        children: [
                          TextSpan(text: l10n.homeAidantsTrust),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: l10n.homeAidantsTrustHighlight,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AidantTile extends StatelessWidget {
  const _AidantTile({
    required this.aidant,
    required this.subtitle,
    required this.onTap,
  });

  final AidantRelation aidant;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: tokens.isDark ? tokens.elevated : Colors.white,
      borderRadius: BorderRadius.circular(Premium.radius),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(Premium.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Premium.radius),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  aidant.initial,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aidant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AidantManageSheet extends ConsumerStatefulWidget {
  const _AidantManageSheet({required this.aidantId});

  final String aidantId;

  @override
  ConsumerState<_AidantManageSheet> createState() => _AidantManageSheetState();
}

class _AidantManageSheetState extends ConsumerState<_AidantManageSheet> {
  late bool _observance;
  late bool _constantes;
  bool _ready = false;

  AidantRelation? _find(List<AidantRelation> list) {
    for (final a in list) {
      if (a.id == widget.aidantId) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final a = _find(ref.read(aidantsControllerProvider).aidants);
    _observance = a?.permissions.observance ?? true;
    _constantes = a?.permissions.constantes ?? false;
    _ready = true;
  }

  Future<void> _savePerms() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(aidantsControllerProvider.notifier).updatePermissions(
            aidantId: widget.aidantId,
            permissions: AidantPermissions(
              observance: _observance,
              constantes: _constantes,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    try {
      final msg =
          await ref.read(aidantsControllerProvider.notifier).revoke(widget.aidantId);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(
        context,
        msg.isEmpty ? l10n.homeAidantsRevoked : msg,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final busy = ref.watch(aidantsControllerProvider).busy;
    final aidant = _find(ref.watch(aidantsControllerProvider).aidants);

    if (!_ready) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.elevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            aidant?.displayName ?? l10n.homeAidantsManageTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeAidantsManageTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.homeAidantsPermObservance),
            value: _observance,
            activeThumbColor: AppColors.primary,
            onChanged: busy
                ? null
                : (v) async {
                    setState(() => _observance = v);
                    await _savePerms();
                  },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.homeAidantsPermConstantes),
            value: _constantes,
            activeThumbColor: AppColors.primary,
            onChanged: busy
                ? null
                : (v) async {
                    setState(() => _constantes = v);
                    await _savePerms();
                  },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : _revoke,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.homeAidantsRevoke),
          ),
        ],
      ),
    );
  }
}
