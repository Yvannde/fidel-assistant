import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
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

/// Seul panneau coloré de l’accueil — prochaine prise + actions.
class NextDoseCard extends StatefulWidget {
  const NextDoseCard({
    super.key,
    required this.next,
    required this.done,
    required this.total,
    required this.busy,
    required this.onConfirm,
    required this.onSnooze,
  });

  final PriseDuJour? next;
  final int done;
  final int total;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onSnooze;

  @override
  State<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<NextDoseCard> {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = widget.next;
    final allDone = next == null && widget.total > 0;
    final colors = allDone
        ? const [AppColors.success, AppColors.successDark]
        : const [AppColors.primarySoft, AppColors.primaryDark];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: allDone
          ? _doneBody(context, l10n)
          : _nextBody(context, l10n, next!),
    );
  }

  Widget _nextBody(
    BuildContext context,
    AppLocalizations l10n,
    PriseDuJour next,
  ) {
    final scheduled = next.heurePrevue.toLocal();
    final late = scheduled.isBefore(_now);
    final delta = late ? _now.difference(scheduled) : scheduled.difference(_now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeNextDoseLabel.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _label,
              ),
            ),
            _CountdownChip(
              text: _countdownText(l10n, delta, late),
              late: late,
            ),
          ],
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
                  Text(
                    next.medicamentNom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  if (next.dosage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      next.dosage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            DayRing(
              done: widget.done,
              total: widget.total,
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
                label: l10n.homeTakeCta,
                icon: IconsaxPlusLinear.tick_circle,
                foreground: AppColors.primaryDark,
                onTap: widget.busy ? null : widget.onConfirm,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _GhostAction(
                label: l10n.homeSnoozeCta,
                onTap: widget.busy ? null : widget.onSnooze,
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
          done: widget.done,
          total: widget.total,
          trackColor: Colors.white.withValues(alpha: 0.22),
          progressColor: Colors.white,
          labelColor: Colors.white,
          size: 72,
          stroke: 7,
        ),
      ],
    );
  }

  static String _countdownText(
    AppLocalizations l10n,
    Duration delta,
    bool late,
  ) {
    final minutes = delta.inMinutes;
    if (minutes < 1) return l10n.homeCountdownNow;
    final value = homeFormatDuration(l10n, minutes);
    return late ? l10n.homeCountdownLate(value) : l10n.homeCountdownIn(value);
  }

  static const TextStyle _label = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Color(0xCCFFFFFF),
  );
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.text, required this.late});

  final String text;
  final bool late;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: late ? Colors.white : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Premium.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            late ? IconsaxPlusLinear.info_circle : IconsaxPlusLinear.clock,
            size: 14,
            color: late ? AppColors.primaryDark : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: late ? AppColors.primaryDark : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidAction extends StatelessWidget {
  const _SolidAction({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Material(
      color: Colors.white.withValues(alpha: onTap == null ? 0.55 : 1),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap!();
              },
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: foreground,
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
