import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/constante_models.dart';
import 'constante_card.dart';

/// Historique récent — constantes uniquement.
class HealthRecentList extends StatelessWidget {
  const HealthRecentList({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<Constante> items;
  final ValueChanged<ConstanteType> onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.healthRecentEmpty,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            height: 1.35,
            color: tokens.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: tokens.border),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onItemTap(items[i].type);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      constanteIcon(items[i].type),
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            constanteLabel(l10n, items[i].type),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd(locale).add_Hm().format(
                                  items[i].mesureAt,
                                ),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      constanteValueText(context, items[i]),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 14,
                      color: tokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
