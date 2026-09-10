import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/alarm_health.dart';

/// Checklist OS / OEM pour que les alarmes H0 sonnent de façon fiable.
class AlarmHealthScreen extends ConsumerStatefulWidget {
  const AlarmHealthScreen({super.key});

  @override
  ConsumerState<AlarmHealthScreen> createState() => _AlarmHealthScreenState();
}

class _AlarmHealthScreenState extends ConsumerState<AlarmHealthScreen>
    with WidgetsBindingObserver {
  AlarmHealthStatus? _status;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final s = await ref.read(alarmHealthServiceProvider).readStatus();
      if (mounted) setState(() => _status = s);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fix(AlarmHealthFix kind) async {
    setState(() => _busy = true);
    try {
      await ref.read(alarmHealthServiceProvider).fix(kind);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _oemTip(AppLocalizations l10n, AlarmHealthStatus s) {
    switch (s.tipKey) {
      case 'xiaomi':
        return l10n.alarmHealthOemXiaomi;
      case 'huawei':
        return l10n.alarmHealthOemHuawei;
      case 'samsung':
        return l10n.alarmHealthOemSamsung;
      case 'oppo':
      case 'oneplus':
        return l10n.alarmHealthOemOppo;
      case 'vivo':
        return l10n.alarmHealthOemVivo;
      case 'transsion':
        return l10n.alarmHealthOemTranssion;
      default:
        return l10n.alarmHealthOemGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final s = _status;
    final isAndroid = !Platform.isIOS && Platform.isAndroid;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.alarmHealthTitle),
          actions: [
            IconButton(
              onPressed: _loading || _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.alarmHealthRefresh,
            ),
          ],
        ),
        body: _loading && s == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    l10n.alarmHealthHint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (s != null) ...[
                    _SummaryBanner(
                      ok: s.allCoreOk,
                      okLabel: l10n.alarmHealthAllOk,
                      warnLabel: l10n.alarmHealthNeedsAttention,
                    ),
                    const SizedBox(height: 16),
                    PremiumCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _CheckTile(
                            ok: s.notifications,
                            title: l10n.alarmHealthNotifTitle,
                            subtitle: l10n.alarmHealthNotifHint,
                            cta: l10n.alarmHealthFixCta,
                            busy: _busy,
                            onFix: () => _fix(AlarmHealthFix.notifications),
                          ),
                          const Divider(height: 1),
                          _CheckTile(
                            ok: s.exactAlarm,
                            title: l10n.alarmHealthExactTitle,
                            subtitle: l10n.alarmHealthExactHint,
                            cta: l10n.alarmHealthFixCta,
                            busy: _busy,
                            onFix: isAndroid
                                ? () => _fix(AlarmHealthFix.exactAlarm)
                                : null,
                          ),
                          const Divider(height: 1),
                          _CheckTile(
                            ok: s.batteryExempt,
                            title: l10n.alarmHealthBatteryTitle,
                            subtitle: l10n.alarmHealthBatteryHint,
                            cta: l10n.alarmHealthFixCta,
                            busy: _busy,
                            onFix: isAndroid
                                ? () => _fix(AlarmHealthFix.batteryExempt)
                                : null,
                          ),
                          const Divider(height: 1),
                          _CheckTile(
                            ok: s.fullScreenIntent,
                            title: l10n.alarmHealthFsiTitle,
                            subtitle: l10n.alarmHealthFsiHint,
                            cta: l10n.alarmHealthFixCta,
                            busy: _busy,
                            onFix: isAndroid && s.sdkInt >= 34
                                ? () =>
                                    _fix(AlarmHealthFix.fullScreenIntent)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (isAndroid && s.oemAutostartLikelyNeeded) ...[
                      const SizedBox(height: 16),
                      PremiumCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  IconsaxPlusLinear.cpu,
                                  color: tokens.textPrimary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.alarmHealthOemTitle,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _oemTip(l10n, s),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: tokens.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _fix(AlarmHealthFix.oemAutostart),
                              child: Text(l10n.alarmHealthOemCta),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _fix(AlarmHealthFix.appDetails),
                      child: Text(l10n.alarmHealthAppDetailsCta),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.ok,
    required this.okLabel,
    required this.warnLabel,
  });

  final bool ok;
  final String okLabel;
  final String warnLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final bg = ok
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.warning.withValues(alpha: 0.14);
    final fg = ok ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Premium.radius),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? IconsaxPlusLinear.tick_circle : IconsaxPlusLinear.warning_2,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok ? okLabel : warnLabel,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.ok,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.busy,
    required this.onFix,
  });

  final bool ok;
  final String title;
  final String subtitle;
  final String cta;
  final bool busy;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return ListTile(
      leading: Icon(
        ok ? IconsaxPlusLinear.tick_circle : IconsaxPlusLinear.close_circle,
        color: ok ? AppColors.success : AppColors.warning,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: tokens.textSecondary,
          height: 1.35,
        ),
      ),
      trailing: ok || onFix == null
          ? null
          : TextButton(
              onPressed: busy ? null : onFix,
              child: Text(cta),
            ),
      isThreeLine: true,
    );
  }
}
