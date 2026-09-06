import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';

class HomeCareScreen extends ConsumerWidget {
  const HomeCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);
    final dash = state.dashboard;
    final padTop = 12 + MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(22, padTop, 22, Premium.navClearance),
      children: [
        Text(
          l10n.navCare,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeCareSubtitle,
          style: TextStyle(color: ThemeTokens.of(context).textSecondary),
        ),
        const SizedBox(height: 20),
        if (!state.hasPatient)
          PremiumCard(
            onTap: () => context.go('/home'),
            child: Text(l10n.homeActivateBody),
          )
        else if (dash == null || dash.traitements.isEmpty)
          PremiumCard(
            onTap: () => context.push('/home/traitement'),
            child: Text(l10n.homeActionTraitementBody),
          )
        else
          for (final t in dash.traitements) ...[
            PremiumCard(
              onTap: t.medicamentsConfigures
                  ? null
                  : () => context.push('/home/medicaments', extra: t.id),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.maladieNom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.medicamentsConfigures
                              ? l10n.homeCareMedsReady
                              : l10n.homeActionMedsBody,
                          style: TextStyle(
                            color: ThemeTokens.of(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    t.medicamentsConfigures
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: t.medicamentsConfigures
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
