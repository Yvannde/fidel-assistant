import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingInfosScreen extends ConsumerStatefulWidget {
  const OnboardingInfosScreen({super.key});

  @override
  ConsumerState<OnboardingInfosScreen> createState() =>
      _OnboardingInfosScreenState();
}

class _OnboardingInfosScreenState extends ConsumerState<OnboardingInfosScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _phoneCtrl;
  DateTime? _birth;
  String _sexe = 'F';
  String? _error;
  var _hydrated = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).infos;
    _nomCtrl = TextEditingController(text: draft.nomComplet);
    _locCtrl = TextEditingController(text: draft.localisation);
    _phoneCtrl = TextEditingController(text: draft.phone);
    _birth = draft.dateNaissance;
    _sexe = draft.sexe;
    _nomCtrl.addListener(_persist);
    _locCtrl.addListener(_persist);
    _phoneCtrl.addListener(_persist);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromServer());
  }

  Future<void> _hydrateFromServer() async {
    if (_hydrated) return;
    _hydrated = true;
    if (_nomCtrl.text.trim().isNotEmpty) return;
    await ref.read(onboardingControllerProvider.notifier).syncFromSessionOrServer();
    if (!mounted) return;
    final draft = ref.read(onboardingControllerProvider).infos;
    if (draft.nomComplet.isNotEmpty && _nomCtrl.text.isEmpty) {
      _nomCtrl.text = draft.nomComplet;
    }
    if (draft.localisation.isNotEmpty && _locCtrl.text.isEmpty) {
      _locCtrl.text = draft.localisation;
    }
    if (draft.phone.isNotEmpty && _phoneCtrl.text.isEmpty) {
      _phoneCtrl.text = draft.phone;
    }
    setState(() {
      _birth ??= draft.dateNaissance;
      if (draft.sexe.isNotEmpty) _sexe = draft.sexe;
    });
  }

  void _persist() {
    ref.read(onboardingControllerProvider.notifier).setInfosDraft(
          InfosDraft(
            nomComplet: _nomCtrl.text,
            dateNaissance: _birth,
            sexe: _sexe,
            localisation: _locCtrl.text,
            phone: _phoneCtrl.text,
          ),
        );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: AppLocalizations.of(context).onboardingBirthLabel,
    );
    if (picked != null) {
      setState(() => _birth = picked);
      _persist();
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birth == null) {
      setState(() => _error = l10n.onboardingBirthRequired);
      return;
    }
    try {
      await ref.read(onboardingControllerProvider.notifier).saveInfos(
            nomComplet: _nomCtrl.text,
            dateNaissance: _birth!,
            sexe: _sexe,
            localisation: _locCtrl.text,
            phone: _phoneCtrl.text,
          );
      if (!mounted) return;
      context.go('/onboarding/besoin-suivi');
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
    final tokens = ThemeTokens.of(context);
    final birthLabel = _birth == null
        ? l10n.onboardingBirthHint
        : '${_birth!.day.toString().padLeft(2, '0')}/${_birth!.month.toString().padLeft(2, '0')}/${_birth!.year}';

    return OnboardingShell(
      stepIndex: 0,
      title: l10n.onboardingInfosTitle,
      subtitle: l10n.onboardingInfosSubtitle,
      lottieAsset: 'assets/lottie/welcome.json',
      lottieIcon: Icons.waving_hand_rounded,
      lottieSize: 148,
      primaryLabel: l10n.onboardingContinue,
      busy: busy,
      onPrimary: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nomCtrl,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.onboardingNameLabel),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: busy ? null : _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.onboardingBirthLabel,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  birthLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _birth == null
                        ? tokens.textSecondary
                        : tokens.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.onboardingSexLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final entry in [
                  ('F', l10n.onboardingSexF),
                  ('M', l10n.onboardingSexM),
                  ('autre', l10n.onboardingSexOther),
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: entry.$1 == 'autre' ? 0 : 8,
                      ),
                      child: _SexChip(
                        label: entry.$2,
                        selected: _sexe == entry.$1,
                        onTap: busy
                            ? null
                            : () {
                                setState(() => _sexe = entry.$1);
                                _persist();
                              },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locCtrl,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.onboardingLocationLabel,
                hintText: l10n.onboardingLocationHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              enabled: !busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.onboardingPhoneLabel,
                hintText: l10n.onboardingPhoneHint,
                helperText: l10n.onboardingPhoneOptional,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  const _SexChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: selected
          ? AppColors.primary
          : tokens.elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : tokens.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
