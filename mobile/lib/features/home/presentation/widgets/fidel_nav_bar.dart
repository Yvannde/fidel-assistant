import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/theme/premium.dart';
import '../../../../l10n/app_localizations.dart';

class FidelNavBar extends StatelessWidget {
  const FidelNavBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final dark = tokens.isDark;
    final items = [
      (IconsaxPlusLinear.home_1, IconsaxPlusBold.home_1, l10n.navHome),
      (IconsaxPlusLinear.health, IconsaxPlusBold.health, l10n.navCare),
      (IconsaxPlusLinear.people, IconsaxPlusBold.people, l10n.navPeople),
      (
        IconsaxPlusLinear.profile_circle,
        IconsaxPlusBold.profile_circle,
        l10n.navYou,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF121A28) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.38 : 0.07),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SizedBox(
          height: Premium.navHeight,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    flex: index == i ? 18 : 11,
                    child: _NavItem(
                      linear: items[i].$1,
                      bold: items[i].$2,
                      label: items[i].$3,
                      selected: index == i,
                      onTap: () {
                        if (index == i) return;
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.linear,
    required this.bold,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData linear;
  final IconData bold;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final iconColor = selected ? Colors.white : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      selected ? bold : linear,
                      key: ValueKey(selected),
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                      widthFactor: selected ? 1 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
