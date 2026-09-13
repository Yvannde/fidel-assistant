import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/dose_slot.dart';
import '../../domain/dashboard_models.dart';
import 'day_ring.dart';

/// Durée lisible : « 45 min », « 2 h », « 2 h 10 ».
String homeFormatDuration(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l10n.homeDurationM(m);
  if (m == 0) return l10n.homeDurationH(h);
  return l10n.homeDurationHm('$h', m.toString().padLeft(2, '0'));
}

/// Seul panneau coloré de l’accueil — prochain créneau + actions.
class NextDoseCard extends StatelessWidget {
  const NextDoseCard({
    super.key,
    required this.slot,
    required this.prises,
    required this.done,
    required this.total,
    required this.busy,
    required this.onConfirm,
    required this.onSnooze,
  });

  final DoseSlot? slot;
  final List<PriseDuJour> prises;
  final int done;
  final int total;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allDone = slot == null && total > 0;

    if (allDone) {
      return _HeroShell(
        variant: _HeroVariant.done,
        child: _doneBody(context, l10n),
      );
    }

    return _TimedHeroShell(
      scheduled: slot!.heurePrevue.toLocal(),
      childBuilder: (now) {
        final late = slot!.heurePrevue.toLocal().isBefore(now);
        return _HeroShell(
          variant: late ? _HeroVariant.late : _HeroVariant.upcoming,
          child: _nextBody(context, l10n, slot!, now: now, late: late),
        );
      },
    );
  }

  Widget _nextBody(
    BuildContext context,
    AppLocalizations l10n,
    DoseSlot slot, {
    required DateTime now,
    required bool late,
  }) {
    final scheduled = slot.heurePrevue.toLocal();
    final actionFg = late ? const Color(0xFF92400E) : AppColors.primaryDark;
    final title = slot.displayTitle(l10n);
    const maxListed = 3;
    final listed = slot.items.take(maxListed).toList();
    final extra = slot.items.length - listed.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeNextDoseLabel.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _label,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.Hm().format(scheduled),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -1.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SlotCountdown(
                    scheduled: scheduled,
                    now: now,
                    late: late,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  if (slot.items.length == 1 && slot.items.first.dosage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      slot.items.first.dosage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    for (final item in listed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    if (extra > 0)
                      Text(
                        '+$extra',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            DayRing(
              done: done,
              total: total,
              trackColor: Colors.white.withValues(alpha: 0.22),
              progressColor: Colors.white,
              labelColor: Colors.white,
              size: 68,
              stroke: 6,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _SolidAction(
                key: ValueKey(slot.slotId),
                label: l10n.homeTakeCta,
                icon: IconsaxPlusLinear.tick_circle,
                foreground: actionFg,
                enabled: !busy,
                onTap: onConfirm,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _GhostAction(
                label: l10n.homeSnoozeCta,
                onTap: busy ? null : onSnooze,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneBody(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeDayProgressLabel.toUpperCase(), style: _label),
              const SizedBox(height: 10),
              Text(
                l10n.homeDayDoneTitle,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.homeDayDoneBody,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        DayRing(
          done: done,
          total: total,
          trackColor: Colors.white.withValues(alpha: 0.22),
          progressColor: Colors.white,
          labelColor: Colors.white,
          size: 72,
          stroke: 7,
        ),
      ],
    );
  }

  static const TextStyle _label = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Color(0xCCFFFFFF),
  );
}

/// Gradient hero + tick pour l’état « en retard ».
class _TimedHeroShell extends StatefulWidget {
  const _TimedHeroShell({
    required this.scheduled,
    required this.childBuilder,
  });

  final DateTime scheduled;
  final Widget Function(DateTime now) childBuilder;

  @override
  State<_TimedHeroShell> createState() => _TimedHeroShellState();
}

class _TimedHeroShellState extends State<_TimedHeroShell> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.childBuilder(_now);
}

enum _HeroVariant { done, late, upcoming }

class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.variant, required this.child});

  final _HeroVariant variant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = switch (variant) {
      _HeroVariant.done => const [AppColors.success, AppColors.successDark],
      _HeroVariant.late => const [Color(0xFFFBBF24), Color(0xFFD97706)],
      _HeroVariant.upcoming =>
        const [AppColors.primarySoft, AppColors.primaryDark],
    };

    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: child,
    );
  }
}

/// Countdown texte — rebuild via [_TimedHeroShell] toutes les 30 s.
class _SlotCountdown extends StatelessWidget {
  const _SlotCountdown({
    required this.scheduled,
    required this.now,
    required this.late,
    required this.l10n,
  });

  final DateTime scheduled;
  final DateTime now;
  final bool late;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final delta = late
        ? now.difference(scheduled)
        : scheduled.difference(now);
    final countdown = _countdownText(l10n, delta, late);

    return Text(
      countdown,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: Colors.white.withValues(alpha: 0.94),
      ),
    );
  }

  String _countdownText(
    AppLocalizations l10n,
    Duration delta,
    bool late,
  ) {
    final minutes = delta.inMinutes;
    if (minutes < 1) return l10n.homeCountdownNow;
    final value = homeFormatDuration(l10n, minutes);
    return late ? l10n.homeCountdownLate(value) : l10n.homeCountdownIn(value);
  }
}

/// Quiet / all-clear — même silhouette gradient que le hero « journée terminée ».
class HomeQuietHero extends StatelessWidget {
  const HomeQuietHero({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const colors = [AppColors.success, AppColors.successDark];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.successDark.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidAction extends StatefulWidget {
  const _SolidAction({
    super.key,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SolidAction> createState() => _SolidActionState();
}

class _SolidActionState extends State<_SolidAction> {
  bool _pressed = false;
  bool _confirmed = false;

  Future<void> _handleTap() async {
    if (!widget.enabled || _confirmed) return;
    HapticFeedback.mediumImpact();
    setState(() => _confirmed = true);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Premium.radiusSm);
    final disabled = !widget.enabled && !_confirmed;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white.withValues(alpha: disabled ? 0.55 : 1),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: disabled ? null : _handleTap,
          onHighlightChanged: (v) {
            if (mounted) setState(() => _pressed = v);
          },
          child: SizedBox(
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _confirmed
                  ? Icon(
                      IconsaxPlusLinear.tick_circle,
                      key: const ValueKey('check'),
                      size: 22,
                      color: widget.foreground,
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, size: 18, color: widget.foreground),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.foreground,
                            ),
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

class _GhostAction extends StatelessWidget {
  const _GhostAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
