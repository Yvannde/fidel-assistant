import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

class HomeNetworkScreen extends ConsumerWidget {
  const HomeNetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPatient = ref.watch(homeControllerProvider).hasPatient;
    final padTop = 12 + MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Premium.screenPad,
        padTop,
        Premium.screenPad,
        Premium.navClearance,
      ),
      children: [
        Text(
          l10n.navPeople,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeNetworkSubtitle,
          style: TextStyle(color: ThemeTokens.of(context).textSecondary),
        ),
        const SizedBox(height: 20),
        _NetworkCard(
          icon: IconsaxPlusBold.profile_2user,
          title: l10n.homeAccompanyTitle,
          subtitle: l10n.homeAccompanyBody,
          onTap: () => context.push('/home/sync'),
        ),
        if (hasPatient) ...[
          const SizedBox(height: 12),
          _NetworkCard(
            icon: IconsaxPlusBold.scan_barcode,
            title: l10n.homeShareCodeTitle,
            subtitle: l10n.homeShareCodeBody,
            onTap: () => context.push('/home/aidants'),
          ),
        ],
      ],
    );
  }
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Premium.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ThemeTokens.of(context).textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            IconsaxPlusLinear.arrow_right_3,
            color: AppColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
