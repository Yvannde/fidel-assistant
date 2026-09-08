import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/home_controller.dart';
import 'home_skeleton.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.initial,
    this.loading = false,
  });

  final String name;
  final String initial;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final dash = ref.watch(homeControllerProvider).dashboard;
    final needsNotif = dash?.prochaineAction == 'activer_notifications';
    final hour = DateTime.now().hour;
    final hello = _hello(l10n, hour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: loading
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeSkeleton(width: 100, height: 12),
                        SizedBox(height: 8),
                        HomeSkeleton(width: 160, height: 22),
                        SizedBox(height: 8),
                        HomeSkeleton(width: 220, height: 12),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hello,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: tokens.textSecondary,
                          ),
                        ),
                        if (name.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              letterSpacing: -0.6,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          l10n.homeTagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: IconsaxPlusLinear.notification,
              tooltip: l10n.homeNotifA11y,
              showDot: needsNotif,
              onTap: () => context.push('/home/notifications'),
            ),
            const SizedBox(width: 6),
            _HeaderIcon(
              icon: IconsaxPlusLinear.setting_2,
              tooltip: l10n.homeSettingsA11y,
              onTap: () => ref.read(homeTabIndexProvider.notifier).state = 3,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      const HomeSkeleton(width: 18, height: 10),
                      const SizedBox(height: 8),
                      HomeSkeleton(
                        width: 34,
                        height: 34,
                        radius: Premium.radiusSm,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          )
        else
          const _WeekStrip(),
      ],
    );
  }

  static String _hello(AppLocalizations l10n, int hour) {
    if (hour < 12) return l10n.homeHelloMorningAnon;
    if (hour < 18) return l10n.homeHelloAfternoonAnon;
    return l10n.homeHelloEveningAnon;
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tokens.isDark ? tokens.elevated : Colors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: tokens.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: tokens.textPrimary),
                if (showDot)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
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

/// Sélecteur L–D uniquement — le graphe d’observance vit dans HomeKpisWeek.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final selected = ref.watch(homeControllerProvider).day;
    final today = homeDateOnly(DateTime.now());
    final start = homeWeekStart(today);
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(
              day: day,
              selected: homeSameDay(day, selected),
              isToday: homeSameDay(day, today),
              tokens: tokens,
              locale: locale,
              onTap: () =>
                  ref.read(homeControllerProvider.notifier).selectDay(day),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.tokens,
    required this.locale,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final ThemeTokens tokens;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected
        ? _cap(DateFormat.EEEE(locale).format(day))
        : _initial(DateFormat.E(locale).format(day));

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(Premium.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            SizedBox(
              height: 16,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: selected ? 10 : 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (tokens.isDark
                        ? tokens.elevated
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(Premium.radiusSm),
                border: isToday && !selected
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      )
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _cap(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  static String _initial(String raw) {
    final c = _cap(raw);
    return c.isEmpty ? c : c[0];
  }
}
