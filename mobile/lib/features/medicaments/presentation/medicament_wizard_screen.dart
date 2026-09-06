import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/application/home_controller.dart';
import '../../home/domain/dashboard_models.dart';
import '../data/medicaments_repository.dart';

class MedicamentWizardScreen extends ConsumerStatefulWidget {
  const MedicamentWizardScreen({super.key, required this.traitementId});

  final String traitementId;

  @override
  ConsumerState<MedicamentWizardScreen> createState() =>
      _MedicamentWizardScreenState();
}

class _MedicamentWizardScreenState extends ConsumerState<MedicamentWizardScreen> {
  final _nom = TextEditingController();
  final _dosage = TextEditingController();
  final _times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  String _forme = 'comprime';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.traitementId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _dosage.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  void _applySuggestion(DoseSuggestion s) {
    _nom.text = s.nom;
    _dosage.text = s.dosage;
    _forme = s.forme.isEmpty ? 'comprime' : s.forme;
    final parsed =
        s.horaires.map(_parseTime).whereType<TimeOfDay>().toList();
    setState(() {
      if (parsed.isNotEmpty) {
        _times
          ..clear()
          ..addAll(parsed);
      }
    });
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && !_times.contains(picked)) {
      setState(() => _times.add(picked));
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_nom.text.trim().isEmpty || _dosage.text.trim().isEmpty) {
      AppToast.error(context, l10n.fieldRequired);
      return;
    }
    if (_times.isEmpty) {
      AppToast.error(context, l10n.medsNeedTime);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(medicamentsRepositoryProvider).createMedicament(
            traitementId: widget.traitementId,
            nom: _nom.text,
            dosage: _dosage.text,
            forme: _forme,
            heures: _times.map(_fmt).toList(),
          );
      await ref.read(homeControllerProvider.notifier).load();
      if (!mounted) return;
      AppToast.success(context, l10n.medsSaved);
      context.go('/home');
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
    final dash = ref.watch(homeControllerProvider).dashboard;
    DashboardTraitement? t;
    for (final item in dash?.traitements ?? const []) {
      if (item.id == widget.traitementId) t = item;
    }

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.medsWizardTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          children: [
            Text(
              l10n.medsWizardSubtitle,
              style: TextStyle(color: ThemeTokens.of(context).textSecondary),
            ),
            if (t != null && t.suggestions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                l10n.medsSuggestions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in t.suggestions)
                    ActionChip(
                      label: Text('${s.nom} ${s.dosage}'),
                      onPressed: () => _applySuggestion(s),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            TextField(
              controller: _nom,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.medsNameLabel),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _dosage,
              decoration: InputDecoration(
                labelText: l10n.medsDoseLabel,
                hintText: l10n.medsDoseHint,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.medsTimesLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _times)
                  InputChip(
                    label: Text(_fmt(t)),
                    onDeleted: () => setState(() => _times.remove(t)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.medsAddTime),
                  onPressed: _addTime,
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.medsSaveCta),
            ),
          ],
        ),
      ),
    );
  }
}
