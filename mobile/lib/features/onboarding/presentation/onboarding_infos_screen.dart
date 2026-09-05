import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingInfosScreen extends ConsumerStatefulWidget {
  const OnboardingInfosScreen({super.key});

  @override
  ConsumerState<OnboardingInfosScreen> createState() =>
      _OnboardingInfosScreenState();
}

class _OnboardingInfosScreenState extends ConsumerState<OnboardingInfosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _birth;
  String _sexe = 'F';
  String? _error;

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
    );
    if (picked != null) setState(() => _birth = picked);
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
    final birthLabel = _birth == null
        ? l10n.onboardingBirthHint
        : '${_birth!.day.toString().padLeft(2, '0')}/${_birth!.month.toString().padLeft(2, '0')}/${_birth!.year}';

    return OnboardingShell(
      title: l10n.onboardingInfosTitle,
      subtitle: l10n.onboardingInfosSubtitle,
      progress: 0.25,
      lottieAsset: 'assets/lottie/welcome.json',
      lottieIcon: Icons.waving_hand_rounded,
      primaryLabel: l10n.onboardingContinue,
      primaryEnabled: true,
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
              decoration: InputDecoration(labelText: l10n.onboardingNameLabel),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: busy ? null : _pickDate,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              child: Text(
                birthLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _birth == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.onboardingSexLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'F', label: Text(l10n.onboardingSexF)),
                ButtonSegment(value: 'M', label: Text(l10n.onboardingSexM)),
                ButtonSegment(
                  value: 'autre',
                  label: Text(l10n.onboardingSexOther),
                ),
              ],
              selected: {_sexe},
              onSelectionChanged: busy
                  ? null
                  : (s) => setState(() => _sexe = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locCtrl,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
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
              decoration: InputDecoration(
                labelText: l10n.onboardingPhoneLabel,
                hintText: l10n.onboardingPhoneHint,
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
