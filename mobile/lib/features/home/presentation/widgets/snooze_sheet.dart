import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import 'next_dose_card.dart' show homeFormatDuration;

/// Choix du report d’une prise — `POST /prises/{id}/reporter` attend une heure
/// absolue, on la calcule à partir de maintenant.
abstract final class SnoozeSheet {
  static Future<Duration?> show(BuildContext context, String medicament) {
    return showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SnoozeBody(medicament: medicament),
    );
  }
}

class _SnoozeBody extends StatelessWidget {
  const _SnoozeBody({required this.medicament});

  final String medicament;

  static const _options = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final now = DateTime.now();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.isDark ? tokens.elevated : Colors.white,
            borderRadius: BorderRadius.circular(Premium.radius),
          ),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.homeSnoozeTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                medicament.isEmpty ? l10n.homeSnoozeBody : medicament,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.35,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              for (final option in _options) ...[
                _Option(
                  label: _optionLabel(l10n, option),
                  at: DateFormat.Hm().format(now.add(option)),
                  onTap: () => Navigator.of(context).pop(option),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 2),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _optionLabel(AppLocalizations l10n, Duration d) =>
      l10n.homeCountdownIn(homeFormatDuration(l10n, d.inMinutes));
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.at,
    required this.onTap,
  });

  final String label;
  final String at;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radiusSm);

    return Material(
      color: tokens.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF4F7FB),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                at,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
