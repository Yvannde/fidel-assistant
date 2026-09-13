import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/dose_slot.dart';
import '../../../services/reminder_alarm_service.dart';
import '../../../services/reminder_sync.dart';
import '../../../services/sync_engine.dart';
import '../application/home_controller.dart';

/// Args pour `/alarm-ring` (multi-medocs + maladie).
class AlarmRingArgs {
  const AlarmRingArgs({
    required this.slot,
    this.alarmId,
  });

  final DoseSlot slot;
  final int? alarmId;

  factory AlarmRingArgs.fromPayload(
    Map<String, dynamic> payload, {
    int? alarmId,
  }) {
    return AlarmRingArgs(
      slot: DoseSlot.fromPayload(payload),
      alarmId: alarmId,
    );
  }
}

/// Écran plein affiché quand l’alarme H0 sonne.
class AlarmRingScreen extends ConsumerStatefulWidget {
  const AlarmRingScreen({
    super.key,
    required this.slot,
    this.alarmId,
  });

  /// Compat constructeur legacy (1 prise).
  factory AlarmRingScreen.legacy({
    Key? key,
    required String priseId,
    String medicamentNom = '',
    String dosage = '',
    String? heurePrevueIso,
    int? alarmId,
    String? maladieNom,
    String? slotId,
    String? traitementId,
  }) {
    DateTime heure = DateTime.now();
    if (heurePrevueIso != null && heurePrevueIso.isNotEmpty) {
      heure = DateTime.tryParse(heurePrevueIso)?.toLocal() ?? heure;
    }
    final tid = traitementId;
    final sid = (slotId != null && slotId.isNotEmpty)
        ? slotId
        : DoseSlot.buildSlotId(traitementId: tid, heurePrevue: heure);
    return AlarmRingScreen(
      key: key,
      alarmId: alarmId,
      slot: DoseSlot(
        slotId: sid,
        traitementId: tid,
        maladieNom: maladieNom ?? '',
        heurePrevue: heure,
        items: [
          if (priseId.isNotEmpty)
            DoseSlotItem(
              priseId: priseId,
              medicamentNom: medicamentNom,
              dosage: dosage,
            ),
        ],
      ),
    );
  }

  final DoseSlot slot;
  final int? alarmId;

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  StreamSubscription<AlarmSet>? _sub;
  bool _busy = false;

  int get _alarmId =>
      widget.alarmId ??
      ReminderAlarmService.alarmNotificationId(widget.slot.slotId);

  @override
  void initState() {
    super.initState();
    // Cancel préavis du slot dès que l’alarme H0 affiche l’UI.
    unawaited(
      ReminderAlarmService.cancelPreavisStatic(widget.slot.slotId),
    );

    _sub = Alarm.ringing.listen((set) {
      if (!mounted) return;
      final still = set.alarms.any((a) => a.id == _alarmId);
      if (!still) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _stopOnly() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Alarm.stop(_alarmId);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _snooze() async {
    if (_busy || widget.slot.priseIds.isEmpty) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final alarms = ref.read(reminderAlarmServiceProvider);
      final prefs = ref.read(alarmPrefsProvider);
      final engine = ref.read(syncEngineProvider);
      final when = DateTime.now().add(Duration(minutes: prefs.snoozeMinutes));

      await alarms.cancelSlot(widget.slot.slotId);
      for (final priseId in widget.slot.priseIds) {
        await engine.enqueueReport(priseId: priseId, nouvelleHeure: when);
      }
      try {
        await engine.flush(force: true);
      } catch (_) {}

      await alarms.scheduleOneShotSlot(widget.slot.copyWithHeure(when));
      try {
        await ref.read(homeControllerProvider.notifier).reloadProjection();
      } catch (_) {}

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final discreet = ref.watch(reminderAlarmServiceProvider).discreet;
    final slot = widget.slot;
    final clock = DateFormat.Hm(l10n.localeName).format(slot.heurePrevue);

    final maladie = slot.maladieNom.trim();
    final title = discreet
        ? 'Fidel · $clock'
        : (maladie.isNotEmpty
            ? maladie
            : () {
                if (slot.items.isEmpty) {
                  return l10n.alarmRingTitleFallback(clock);
                }
                if (slot.items.length == 1) {
                  final i = slot.items.first;
                  final nom = i.medicamentNom.trim();
                  final dosage = i.dosage.trim();
                  if (nom.isEmpty && dosage.isEmpty) {
                    return l10n.alarmRingTitleFallback(clock);
                  }
                  if (dosage.isEmpty) return nom;
                  if (nom.isEmpty) return dosage;
                  return '$nom · $dosage';
                }
                return l10n.localeName.startsWith('en')
                    ? '${slot.items.length} medications'
                    : '${slot.items.length} médicaments';
              }());

    final body = discreet
        ? l10n.alarmRingBodyDiscreet(clock)
        : (maladie.isNotEmpty
            ? (l10n.localeName.startsWith('en')
                ? "It's time — $clock"
                : "C'est l'heure — $clock")
            : l10n.alarmRingBody(clock));

    final medLines = discreet
        ? const <String>[]
        : [
            for (final i in slot.items)
              if (i.label.isNotEmpty) i.label,
          ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.alarm_rounded,
                  size: 88,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                if (medLines.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...medLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _stopOnly,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.alarmRingStop),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _snooze,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      side: BorderSide(
                        color:
                            theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.alarmRingSnooze),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ouvre `/alarm-ring` quand une alarme package commence à sonner.
void bindAlarmRingingNavigation(GoRouter router) {
  Alarm.ringing.listen((AlarmSet set) {
    if (set.alarms.isEmpty) return;
    final alarm = set.alarms.first;
    final payload = parseReminderPayload(alarm.payload);
    final slot = DoseSlot.fromPayload(payload);

    // Cancel préavis dès le ring H0 (même sans UI encore montée).
    unawaited(ReminderAlarmService.cancelPreavisStatic(slot.slotId));

    final args = AlarmRingArgs(slot: slot, alarmId: alarm.id);
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    if (loc == '/alarm-ring') return;
    router.go('/alarm-ring', extra: args);
  });
}
