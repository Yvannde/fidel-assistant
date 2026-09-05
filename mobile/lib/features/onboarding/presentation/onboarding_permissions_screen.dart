import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingPermissionsScreen extends ConsumerStatefulWidget {
  const OnboardingPermissionsScreen({super.key});

  @override
  ConsumerState<OnboardingPermissionsScreen> createState() =>
      _OnboardingPermissionsScreenState();
}

class _OnboardingPermissionsScreenState
    extends ConsumerState<OnboardingPermissionsScreen> {
  String? _error;

  Future<void> _finish({required bool requestOs}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);

    var notifications = false;
    var batterie = false;

    if (requestOs) {
      final notif = await Permission.notification.request();
      notifications = notif.isGranted;
      if (Platform.isAndroid) {
        final batt = await Permission.ignoreBatteryOptimizations.request();
        batterie = batt.isGranted;
      }
    }

    try {
      await ref.read(onboardingControllerProvider.notifier).savePermissions(
            notificationsAccordees: notifications,
            batterieExemptee: batterie,
          );
      await ref.read(onboardingControllerProvider.notifier).complete();
      if (!mounted) return;
      AppToast.success(context, l10n.onboardingDoneToast);
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.genericError);
      AppToast.error(context, l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(onboardingControllerProvider).busy;
    final theme = Theme.of(context);

    return OnboardingShell(
      title: l10n.onboardingPermsTitle,
      subtitle: l10n.onboardingPermsSubtitle,
      progress: 1,
      lottieAsset: 'assets/lottie/notifications.json',
      lottieIcon: Icons.notifications_active_outlined,
      primaryLabel: l10n.onboardingPermsAllow,
      secondaryLabel: l10n.onboardingPermsLater,
      busy: busy,
      onBack: () => context.go('/onboarding/traitement'),
      onPrimary: () => _finish(requestOs: true),
      onSecondary: () => _finish(requestOs: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermRow(
            icon: Icons.notifications_outlined,
            title: l10n.onboardingPermsNotifTitle,
            body: l10n.onboardingPermsNotifBody,
          ),
          const SizedBox(height: 16),
          _PermRow(
            icon: Icons.battery_saver_outlined,
            title: l10n.onboardingPermsBatteryTitle,
            body: l10n.onboardingPermsBatteryBody,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
