import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../application/home_controller.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_settings_tile.dart';

class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(homeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final profile = state.profile;
    final padTop = 12 + MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Premium.screenPad,
          padTop,
          Premium.screenPad,
          Premium.navClearance,
        ),
        children: [
          Text(
            l10n.navYou,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.profileSubtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (profile != null) ...[
            ProfileHeaderCard(profile: profile),
            const SizedBox(height: 22),
          ] else if (state.loading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],

          ProfileSectionCard(
            title: l10n.profileSectionPrefs,
            children: [
              ProfileSettingsTile(
                icon: IconsaxPlusLinear.language_circle,
                title: l10n.profileLanguage,
                subtitle: _languageLabel(l10n, locale),
                onTap: () => _pickLanguage(context, ref),
              ),
              ProfileSettingsTile(
                icon: IconsaxPlusLinear.brush_2,
                title: l10n.homeThemeLabel,
                subtitle: _themeLabel(l10n, themeMode),
                onTap: () => _pickTheme(context, ref, themeMode),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 18),

          ProfileSectionCard(
            title: l10n.profileSectionFollowUp,
            children: [
              ProfileSettingsTile(
                icon: IconsaxPlusLinear.notification,
                title: l10n.profileNotifications,
                subtitle: l10n.profileNotificationsHint,
                onTap: () => context.push('/home/notifications'),
              ),
              ProfileSettingsTile(
                icon: IconsaxPlusLinear.people,
                title: l10n.homeShareCodeTitle,
                subtitle: state.hasPatient
                    ? l10n.profileAidantsHint
                    : l10n.profileAidantsLocked,
                enabled: state.hasPatient,
                onTap: state.hasPatient
                    ? () => context.push('/home/aidants')
                    : null,
                showDivider: !state.hasPatient,
              ),
              if (!state.hasPatient)
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.health,
                  title: l10n.homeActivateTitle,
                  subtitle: l10n.homeActivateBody,
                  onTap: () => _activateFollowUp(context, ref),
                  showDivider: false,
                ),
            ],
          ),
          const SizedBox(height: 18),

          ProfileSectionCard(
            title: l10n.profileSectionLegal,
            children: [
              ProfileSettingsTile(
                icon: IconsaxPlusLinear.document_text,
                title: l10n.profileCgu,
                subtitle: l10n.profileCguVersion(AppConfig.cguCurrentVersion),
                onTap: null,
                enabled: false,
                trailing: const SizedBox.shrink(),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                l10n.logout,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.homeThemeLight,
      ThemeMode.dark => l10n.homeThemeDark,
      ThemeMode.system => l10n.homeThemeSystem,
    };
  }

  static String _languageLabel(AppLocalizations l10n, Locale? locale) {
    final code = locale?.languageCode ?? 'fr';
    return code == 'en' ? l10n.languageEnglish : l10n.languageFrench;
  }

  static Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.homeThemeSystem),
                trailing: current == ThemeMode.system
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.system),
              ),
              ListTile(
                title: Text(l10n.homeThemeLight),
                trailing: current == ThemeMode.light
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.light),
              ),
              ListTile(
                title: Text(l10n.homeThemeDark),
                trailing: current == ThemeMode.dark
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, ThemeMode.dark),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen != null) {
      await ref.read(themeControllerProvider.notifier).setThemeMode(chosen);
    }
  }

  static Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(localeControllerProvider)?.languageCode ?? 'fr';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageFrench),
                trailing: current == 'fr'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'fr'),
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: current == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen == current) return;

    await ref
        .read(localeControllerProvider.notifier)
        .setLocale(Locale(chosen));

    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(langue: chosen);
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
    } catch (_) {
      // Langue locale déjà appliquée ; sync API best-effort.
    }
  }

  static Future<void> _activateFollowUp(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(homeControllerProvider.notifier).activateFollowUp();
      if (context.mounted) {
        AppToast.success(context, l10n.profileActivateOk);
        ref.read(homeTabIndexProvider.notifier).state = 0;
      }
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(authSessionProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}
