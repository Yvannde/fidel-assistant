import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingOptionTile extends StatelessWidget {
  const OnboardingOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.multi = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool multi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: tokens.isDark ? 0.2 : 0.07)
            : tokens.elevated,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.primary : tokens.border,
                width: selected ? 1.8 : 1.1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? (multi
                          ? Icons.check_box_rounded
                          : Icons.radio_button_checked_rounded)
                      : (multi
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.radio_button_off_rounded),
                  color: selected ? AppColors.primary : tokens.divider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
