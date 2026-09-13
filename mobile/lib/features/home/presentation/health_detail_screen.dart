import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/constante_models.dart';
import 'widgets/add_constante_sheet.dart';
import 'widgets/constante_card.dart';
import 'widgets/sparkline.dart';

/// Détail d’un type de constante — courbe + historique.
class HealthDetailScreen extends ConsumerWidget {
  const HealthDetailScreen({super.key, required this.typeCode});

  final String typeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = ConstanteType.fromCode(typeCode);
    if (type == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.genericError)),
      );
    }

    final state = ref.watch(homeControllerProvider);
    final points = state.constantes
        .where((c) => c.type == type)
        .toList()
      ..sort((a, b) => a.mesureAt.compareTo(b.mesureAt));
    final series = points.isEmpty
        ? null
        : ConstanteSeries(type: type, points: points);
    final latest = points.isEmpty ? null : points.last;
    final previous = points.length >= 2 ? points[points.length - 2] : null;
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: Premium.canvas(
        Theme.of(context).brightness == Brightness.dark,
      ),
      appBar: AppBar(
        title: Text(constanteLabel(l10n, type)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          AddConstanteSheet.show(context, initial: type);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(IconsaxPlusLinear.add),
        label: Text(l10n.healthAddCta),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Premium.screenPad,
          8,
          Premium.screenPad,
          Premium.navClearance + 80,
        ),
        children: [
          if (latest != null) ...[
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(constanteIcon(type), color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.healthLatestMeasure,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    constanteValueText(context, latest),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMMd(locale).add_Hm().format(latest.mesureAt),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (previous != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _deltaText(context, latest, previous),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (series != null && series.points.length >= 2) ...[
              const SizedBox(height: 16),
              PremiumCard(
                child: Sparkline(
                  values: [for (final p in series.points) p.systolique],
                  secondary: type.isPaired
                      ? [for (final p in series.points) p.diastolique ?? 0]
                      : null,
                  color: AppColors.primary,
                  surface: tokens.isDark ? tokens.elevated : Colors.white,
                  height: 120,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Text(
              l10n.healthHistory,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Column(
                children: [
                  for (var i = points.length - 1; i >= 0; i--) ...[
                    if (i < points.length - 1)
                      Divider(height: 1, color: tokens.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat.yMMMd(locale)
                                  .add_Hm()
                                  .format(points[i].mesureAt),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            constanteValueText(context, points[i]),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.healthNoDataForType(constanteLabel(l10n, type)),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () =>
                        AddConstanteSheet.show(context, initial: type),
                    child: Text(l10n.healthAddCta),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _deltaText(
    BuildContext context,
    Constante latest,
    Constante previous,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: latest.type.decimals,
    );
    final delta = latest.systolique - previous.systolique;
    final sign = delta > 0 ? '+' : '−';
    return '$sign${format.format(delta.abs())} ${latest.unite}';
  }
}
