import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import 'widgets/profile_settings_tile.dart';

const _timezones = [
  'Africa/Douala',
  'Africa/Lagos',
  'Africa/Kinshasa',
  'Africa/Abidjan',
  'UTC',
  'Europe/Paris',
];

/// Téléphone + fuseau — `PATCH /auth/me`.
class ProfileAccountScreen extends ConsumerStatefulWidget {
  const ProfileAccountScreen({super.key});

  @override
  ConsumerState<ProfileAccountScreen> createState() =>
      _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends ConsumerState<ProfileAccountScreen> {
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(homeControllerProvider).profile;
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(phone: _phone.text.trim());
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
      if (mounted) AppToast.success(context, l10n.profileSaved);
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : l10n.genericError,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTimezone() async {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.read(homeControllerProvider).profile?.fuseauHoraire ?? 'Africa/Douala';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final tz in _timezones)
                ListTile(
                  title: Text(tz),
                  trailing: tz == current
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, tz),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen == current) return;
    try {
      final updated = await ref
          .read(homeRepositoryProvider)
          .patchMe(fuseauHoraire: chosen);
      ref.read(homeControllerProvider.notifier).updateProfile(updated);
      if (mounted) AppToast.success(context, l10n.profileSaved);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final profile = ref.watch(homeControllerProvider).profile;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.profileAccountTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.profileAccountHint,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.profilePhone,
                      prefixIcon: const Icon(IconsaxPlusLinear.call),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _savePhone,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ProfileSectionCard(
              title: l10n.profileTimezone,
              children: [
                ProfileSettingsTile(
                  icon: IconsaxPlusLinear.clock,
                  title: l10n.profileTimezone,
                  subtitle: profile?.fuseauHoraire ?? 'Africa/Douala',
                  onTap: _pickTimezone,
                  showDivider: false,
                ),
              ],
            ),
            if (profile?.email.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              ProfileSectionCard(
                title: l10n.profileEmail,
                children: [
                  ProfileSettingsTile(
                    icon: IconsaxPlusLinear.sms,
                    title: profile!.email,
                    enabled: false,
                    onTap: null,
                    trailing: const SizedBox.shrink(),
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
