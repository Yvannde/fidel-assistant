import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dashboard_models.dart';

/// En-tête compte : avatar, nom, fiche santé (bande clinique), email, rôles.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.profile});

  final HomeProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final name = profile.headerName.isEmpty
        ? l10n.profileFallbackName
        : profile.headerName;

    final ficheItems = <({String label, String value})>[
      if (profile.groupeRhesusLabel != null)
        (label: l10n.profileFicheSanteGroupeShort, value: profile.groupeRhesusLabel!),
      if (profile.electrophoreseChip != null)
        (
          label: l10n.profileFicheSanteElectroShort,
          value: profile.electrophoreseChip!,
        ),
      if (profile.tailleChip != null)
        (label: l10n.profileFicheSanteTailleShort, value: profile.tailleChip!),
    ];

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.border),
              color: tokens.isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.06),
            ),
            child: Text(
              profile.initial,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: tokens.textPrimary,
                  ),
                ),
                if (profile.email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
                if (ficheItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FicheSanteStrip(items: ficheItems),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (profile.hasPatientProfile)
                      _RoleBadge(label: l10n.profileChipPatient),
                    if (profile.isAidant)
                      _RoleBadge(label: l10n.profileChipAidant),
                    if (!profile.hasPatientProfile && !profile.isAidant)
                      _RoleBadge(label: l10n.profileChipAccount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bande identité médicale — clinique, bordée, sans pastilles « wellness ».
class _FicheSanteStrip extends StatelessWidget {
  const _FicheSanteStrip({required this.items});

  final List<({String label, String value})> items;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: tokens.divider.withValues(alpha: 0.7),
              ),
            Expanded(
              child: _FicheMetric(
                label: items[i].label,
                value: items[i].value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FicheMetric extends StatelessWidget {
  const _FicheMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        border: Border.all(color: tokens.border),
        color: Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}
