import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

enum _Moment { morning, afternoon, evening }

/// Timeline des prises — contenu à placer dans un panneau parent.
/// [embedded] : pas de carte autour (défaut true pour le panneau Aujourd’hui).
class DoseTimeline extends StatelessWidget {
  const DoseTimeline({
    super.key,
    required this.prises,
    required this.now,
    required this.busy,
    required this.onConfirm,
    this.embedded = true,
  });

  final List<PriseDuJour> prises;
  final DateTime now;
  final bool busy;
  final ValueChanged<PriseDuJour> onConfirm;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    if (prises.isEmpty) {
      final empty = Row(
        children: [
          Icon(
            IconsaxPlusLinear.calendar_1,
            color: tokens.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.homeNoDoses,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.35,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      );
      if (embedded) return empty;
      return PremiumCard(child: empty);
    }

    final sorted = [...prises]
      ..sort((a, b) => a.heurePrevue.compareTo(b.heurePrevue));

    final nextId = _nextUntakenId(sorted, now);

    final groups = <_Moment, List<PriseDuJour>>{};
    for (final p in sorted) {
      groups.putIfAbsent(_momentOf(p.heurePrevue.toLocal()), () => []).add(p);
    }

    final rows = <Widget>[];
    var index = 0;
    final lastIndex = sorted.length - 1;

    for (final moment in _Moment.values) {
      final items = groups[moment];
      if (items == null || items.isEmpty) continue;
      rows.add(_MomentHeader(moment: moment, l10n: l10n, tokens: tokens));
      for (final prise in items) {
        rows.add(
          _DoseRow(
            prise: prise,
            now: now,
            busy: busy,
            isFirst: index == 0,
            isLast: index == lastIndex,
            isNext: prise.id == nextId,
            onConfirm: () => onConfirm(prise),
          ),
        );
        index++;
      }
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
    if (embedded) return body;
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: body,
    );
  }

  /// Prochaine prise non confirmée : overdue la plus ancienne, sinon la plus proche.
  static String? _nextUntakenId(List<PriseDuJour> sorted, DateTime now) {
    PriseDuJour? overdue;
    PriseDuJour? upcoming;
    for (final p in sorted) {
      if (p.isTaken) continue;
      final t = p.heurePrevue.toLocal();
      if (t.isBefore(now) || t.isAtSameMomentAs(now)) {
        overdue ??= p;
      } else {
        upcoming ??= p;
        break;
      }
    }
    return (overdue ?? upcoming)?.id;
  }

  static _Moment _momentOf(DateTime time) {
    if (time.hour < 12) return _Moment.morning;
    if (time.hour < 18) return _Moment.afternoon;
    return _Moment.evening;
  }
}

class _MomentHeader extends StatelessWidget {
  const _MomentHeader({
    required this.moment,
    required this.l10n,
    required this.tokens,
  });

  final _Moment moment;
  final AppLocalizations l10n;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (moment) {
      _Moment.morning => (IconsaxPlusLinear.sun_1, l10n.homeMomentMorning),
      _Moment.afternoon => (IconsaxPlusLinear.sun, l10n.homeMomentAfternoon),
      _Moment.evening => (IconsaxPlusLinear.moon, l10n.homeMomentEvening),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, size: 14, color: tokens.textSecondary),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.prise,
    required this.now,
    required this.busy,
    required this.isFirst,
    required this.isLast,
    required this.isNext,
    required this.onConfirm,
  });

  final PriseDuJour prise;
  final DateTime now;
  final bool busy;
  final bool isFirst;
  final bool isLast;
  final bool isNext;
  final VoidCallback onConfirm;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final taken = prise.isTaken;
    final late = !taken && prise.isLate(now);
    final accent = taken
        ? AppColors.success
        : late
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.12 : 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Premium.radiusSm),
      ),
      child: Row(
        children: [
          _Rail(
            accent: accent,
            filled: taken,
            emphasized: isNext,
            isFirst: isFirst,
            isLast: isLast,
            tokens: tokens,
          ),
          SizedBox(
            width: 46,
            child: Text(
              DateFormat.Hm().format(prise.heurePrevue.toLocal()),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: taken
                    ? tokens.textSecondary
                    : isNext
                        ? AppColors.primary
                        : tokens.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prise.medicamentNom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                    height: 1.2,
                    color: taken ? tokens.textSecondary : tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  late ? '${prise.dosage} · ${l10n.homeStatLate}' : prise.dosage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: late ? FontWeight.w700 : FontWeight.w500,
                    color: late ? AppColors.warning : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (taken)
            Text(
              l10n.homeTakenBadge,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            )
          else
            _ConfirmButton(
              accent: accent,
              tooltip: l10n.homeTakeCta,
              onTap: busy ? null : onConfirm,
            ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.accent,
    required this.filled,
    required this.emphasized,
    required this.isFirst,
    required this.isLast,
    required this.tokens,
  });

  final Color accent;
  final bool filled;
  final bool emphasized;
  final bool isFirst;
  final bool isLast;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final line = tokens.isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFD6DEE8);
    final dotSize = emphasized ? 14.0 : 12.0;

    return SizedBox(
      width: 26,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : line,
            ),
          ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accent : Colors.transparent,
              border: Border.all(
                color: accent,
                width: emphasized ? 2.2 : 1.8,
              ),
              boxShadow: emphasized && !filled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.accent,
    required this.tooltip,
    required this.onTap,
  });

  final Color accent;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Premium.radiusSm);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap!();
                },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(IconsaxPlusLinear.tick_circle, size: 18, color: accent),
          ),
        ),
      ),
    );
  }
}
