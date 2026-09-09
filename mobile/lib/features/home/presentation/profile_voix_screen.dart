import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/profile_settings_models.dart';
import 'widgets/home_skeleton.dart';

/// Voix de rappel — `GET/PUT /patients/me/voix-rappel`.
class ProfileVoixScreen extends ConsumerStatefulWidget {
  const ProfileVoixScreen({super.key});

  @override
  ConsumerState<ProfileVoixScreen> createState() => _ProfileVoixScreenState();
}

class _ProfileVoixScreenState extends ConsumerState<ProfileVoixScreen> {
  VoixRappel? _voix;
  bool _loading = true;
  bool _busy = false;

  static const _maxBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final v = await ref.read(homeRepositoryProvider).fetchVoixRappel();
      if (mounted) setState(() => _voix = v);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useSysteme() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final v = await ref.read(homeRepositoryProvider).putVoixRappelSysteme();
      if (mounted) {
        setState(() => _voix = v);
        AppToast.success(context, l10n.profileSaved);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCustom() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'ogg', 'opus'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    final name = file.name;

    if ((bytes == null || bytes.isEmpty) && (path == null || path.isEmpty)) {
      AppToast.error(context, l10n.profileVoixPickFailed);
      return;
    }
    final size = bytes?.length ?? file.size;
    if (size > _maxBytes) {
      AppToast.error(context, l10n.profileVoixTooLarge);
      return;
    }

    setState(() => _busy = true);
    try {
      final v = await ref.read(homeRepositoryProvider).putVoixRappelPersonnalisee(
            filename: name,
            bytes: bytes ?? const <int>[],
            filePath: path,
          );
      if (mounted) {
        setState(() => _voix = v);
        AppToast.success(context, l10n.profileSaved);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final isCustom = _voix?.isPersonnalisee == true;

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.profileVoixTitle),
        ),
        body: _loading
            ? const ProfilePageSkeleton(rows: 2)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    l10n.profileVoixHint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            IconsaxPlusLinear.volume_high,
                            color: AppColors.primary,
                          ),
                          title: Text(l10n.profileVoixSystem),
                          subtitle: Text(l10n.profileVoixSystemHint),
                          trailing: !isCustom
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: _busy ? null : _useSysteme,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            IconsaxPlusLinear.microphone_2,
                            color: AppColors.primary,
                          ),
                          title: Text(l10n.profileVoixCustom),
                          subtitle: Text(
                            isCustom
                                ? l10n.profileVoixCustomActive
                                : l10n.profileVoixCustomHint,
                          ),
                          trailing: isCustom
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: _busy ? null : _pickCustom,
                        ),
                      ],
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: HomeSkeleton(width: 36, height: 36, radius: 18),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
