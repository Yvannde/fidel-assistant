import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import '../../domain/dashboard_models.dart';
import 'constante_card.dart';

enum CareFeedKind { prise, constante, checkIn }

class CareFeedItem {
  const CareFeedItem({
    required this.kind,
    required this.at,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.prisePending = false,
  });

  final CareFeedKind kind;
  final DateTime at;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool prisePending;

  static List<CareFeedItem> build({
    required AppLocalizations l10n,
    required BuildContext context,
    required List<PriseDuJour> prises,
    required List<Constante> constantes,
    required CheckInEntry? checkIn,
    int maxItems = 12,
  }) {
    final items = <CareFeedItem>[];

    for (final p in prises) {
      final status = p.isTaken
          ? l10n.homeCareFeedPriseTaken
          : (p.isMissed
              ? l10n.homeCareFeedPriseMissed
              : l10n.homeCareFeedPrisePending);
      items.add(
        CareFeedItem(
          kind: CareFeedKind.prise,
          at: p.heurePrevue,
          title: p.medicamentNom,
          subtitle: '${p.dosage} · $status',
          icon: p.isTaken
              ? IconsaxPlusLinear.tick_circle
              : (p.isMissed
                  ? IconsaxPlusLinear.close_circle
                  : IconsaxPlusLinear.clock),
          prisePending: p.isPending,
        ),
      );
    }

    for (final c in constantes) {
      items.add(
        CareFeedItem(
          kind: CareFeedKind.constante,
          at: c.mesureAt,
          title: constanteLabel(l10n, c.type),
          subtitle: constanteValueText(context, c),
          icon: constanteIcon(c.type),
        ),
      );
    }

    if (checkIn != null) {
      final day = checkIn.date;
      items.add(
        CareFeedItem(
          kind: CareFeedKind.checkIn,
          at: DateTime(day.year, day.month, day.day, 12),
          title: l10n.homeCareProgressCheckIn,
          subtitle: checkIn.isOk
              ? l10n.homeCheckInDoneOk
              : l10n.homeCheckInDoneBad,
          icon: IconsaxPlusLinear.heart,
        ),
      );
    }

    items.sort((a, b) => b.at.compareTo(a.at));
    if (items.length <= maxItems) return items;
    return items.sublist(0, maxItems);
  }
}

/// Journal style référence : cartes blanches séparées, ombre douce, chevron.
class CareActivityFeed extends StatelessWidget {
  const CareActivityFeed({
    super.key,
    required this.items,
    required this.onAddVital,
    required this.onPendingPriseTap,
  });

  final List<CareFeedItem> items;
  final VoidCallback onAddVital;
  final VoidCallback onPendingPriseTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.jm(locale);

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: tokens.isDark ? tokens.elevated : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: tokens.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Text(
          l10n.homeCareJournalEmpty,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            height: 1.4,
            color: tokens.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _FeedCard(
            item: items[i],
            timeLabel: timeFmt.format(items[i].at),
            onTap: () {
              HapticFeedback.selectionClick();
              if (items[i].kind == CareFeedKind.constante) {
                onAddVital();
              } else if (items[i].prisePending) {
                onPendingPriseTap();
              }
            },
          ),
        ],
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });

  final CareFeedItem item;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final tappable =
        item.kind == CareFeedKind.constante || item.prisePending;

    return Material(
      color: tokens.isDark ? tokens.elevated : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: tappable ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: tokens.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9B8FB8).withValues(alpha: 0.14),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: const Color(0xFF8B7FA8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                      '$timeLabel · ${item.subtitle}',
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
                Icons.chevron_right_rounded,
                size: 22,
                color: tokens.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
