import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Contacts d’urgence — SOS / escalade (UI premium).
class ProfileContactsUrgenceScreen extends ConsumerStatefulWidget {
  const ProfileContactsUrgenceScreen({super.key});

  @override
  ConsumerState<ProfileContactsUrgenceScreen> createState() =>
      _ProfileContactsUrgenceScreenState();
}

class _ProfileContactsUrgenceScreenState
    extends ConsumerState<ProfileContactsUrgenceScreen> {
  List<ContactUrgence> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await ref.read(homeRepositoryProvider).listContactsUrgence();
      if (mounted) setState(() => _items = list);
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

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _AddContactSheet(),
    );
    if (created == true) await _load();
  }

  Future<void> _delete(ContactUrgence c) async {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
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
                  const SizedBox(height: 16),
                  Text(
                    l10n.profileContactDelete,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileContactDeleteConfirm(c.nom),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.error,
                          ),
                          child: Text(l10n.commonDelete),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    try {
      await ref.read(homeRepositoryProvider).deleteContactUrgence(c.id);
      if (mounted) {
        AppToast.success(context, l10n.profileSaved);
      }
      await _load();
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

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.profileContactsTitle),
          actions: [
            IconButton(
              onPressed: _openAddSheet,
              icon: const Icon(IconsaxPlusLinear.add),
              tooltip: l10n.profileContactAdd,
            ),
          ],
        ),
        body: _loading
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: const [
                  HomeSkeleton(width: 220, height: 14),
                  SizedBox(height: 16),
                  ProfileListSkeleton(count: 3),
                ],
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      l10n.profileContactsHint,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_items.isEmpty)
                      PremiumCard(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        child: Column(
                          children: [
                            Icon(
                              IconsaxPlusLinear.call,
                              size: 32,
                              color: AppColors.primary.withValues(alpha: 0.85),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.profileContactsEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.profileContactsEmptyHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                height: 1.4,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      PremiumCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onLongPress: () => _delete(_items[i]),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      8,
                                      14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary.withValues(
                                              alpha: tokens.isDark ? 0.2 : 0.1,
                                            ),
                                          ),
                                          child: Text(
                                            _items[i].nom.isEmpty
                                                ? '?'
                                                : _items[i].nom[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _items[i].nom,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: tokens.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${_items[i].relation} · ${_items[i].telephone}',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontSize: 12,
                                                  color: tokens.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            IconsaxPlusLinear.trash,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          onPressed: () => _delete(_items[i]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (i < _items.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 70,
                                  color: tokens.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _openAddSheet,
                        icon: const Icon(IconsaxPlusLinear.add, size: 20),
                        label: Text(
                          l10n.profileContactAdd,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet();

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  final _rel = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    _rel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final nom = _nom.text.trim();
    final tel = _tel.text.trim();
    final rel = _rel.text.trim();
    if (nom.isEmpty || tel.isEmpty || rel.isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.selectionClick();
    try {
      await ref.read(homeRepositoryProvider).addContactUrgence(
            nom: nom,
            telephone: tel,
            relation: rel,
          );
      if (!mounted) return;
      AppToast.success(context, l10n.profileSaved);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ApiException ? e.message : l10n.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.isDark ? tokens.elevated : Colors.white,
              borderRadius: BorderRadius.circular(Premium.radius),
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Text(
                    l10n.profileContactAdd,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profileContactAddHint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      height: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.profileContactName,
                      prefixIcon: const Icon(IconsaxPlusLinear.user),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tel,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.profilePhone,
                      prefixIcon: const Icon(IconsaxPlusLinear.call),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rel,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saving ? null : _save(),
                    decoration: InputDecoration(
                      labelText: l10n.profileContactRelation,
                      prefixIcon: const Icon(IconsaxPlusLinear.people),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.commonSave,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
