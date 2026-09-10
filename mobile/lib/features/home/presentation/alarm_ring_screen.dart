import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/reminder_alarm_service.dart';
import '../../../services/reminder_sync.dart';
import '../../../services/scheduled_dose.dart';
import '../application/home_controller.dart';

/// Écran plein affiché quand l’alarme H0 sonne.
class AlarmRingScreen extends ConsumerStatefulWidget {
  const AlarmRingScreen({
    super.key,
    required this.priseId,
    this.medicamentNom = '',
    this.dosage = '',
    this.heurePrevueIso,
    this.alarmId,
  });

  final String priseId;
  final String medicamentNom;
  final String dosage;
  final String? heurePrevueIso;
  final int? alarmId;

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  StreamSubscription<AlarmSet>? _sub;
  bool _busy = false;

  int get _alarmId =>
      widget.alarmId ?? ReminderAlarmService.alarmNotificationId(widget.priseId);

  @override
  void initState() {
    super.initState();
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
    if (_busy || widget.priseId.isEmpty) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final alarms = ref.read(reminderAlarmServiceProvider);
      final prefs = ref.read(alarmPrefsProvider);
      final queue = ref.read(pendingPriseSyncQueueProvider);
      final repo = ref.read(homeRepositoryProvider);
      final when = DateTime.now().add(Duration(minutes: prefs.snoozeMinutes));

      await alarms.cancelPrise(widget.priseId);
      await queue.enqueueReport(priseId: widget.priseId, nouvelleHeure: when);
      try {
        await repo.reportPrise(widget.priseId, when);
        await queue.flush(repo);
      } catch (_) {}

      await alarms.scheduleOneShot(
        ScheduledDose(
          priseId: widget.priseId,
          medicamentNom: widget.medicamentNom,
          dosage: widget.dosage,
          heurePrevue: when,
        ),
      );
      try {
        await ref.read(homeControllerProvider.notifier).load(secondary: false);
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
    final clock = () {
      if (widget.heurePrevueIso != null && widget.heurePrevueIso!.isNotEmpty) {
        try {
          final dt = DateTime.parse(widget.heurePrevueIso!).toLocal();
          return DateFormat.Hm(l10n.localeName).format(dt);
        } catch (_) {}
      }
      return DateFormat.Hm(l10n.localeName).format(DateTime.now());
    }();

    final title = discreet
        ? 'Fidel · $clock'
        : () {
            final nom = widget.medicamentNom.trim();
            final dosage = widget.dosage.trim();
            if (nom.isEmpty && dosage.isEmpty) {
              return l10n.alarmRingTitleFallback(clock);
            }
            if (dosage.isEmpty) return nom;
            if (nom.isEmpty) return dosage;
            return '$nom · $dosage';
          }();

    final body = discreet
        ? l10n.alarmRingBodyDiscreet(clock)
        : l10n.alarmRingBody(clock);

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
    final priseId = payload['priseId'] as String? ?? '';
    final nom = payload['medicamentNom'] as String? ?? '';
    final dosage = payload['dosage'] as String? ?? '';
    final heure = payload['heurePrevue'] as String? ?? '';
    final q = <String, String>{
      'priseId': priseId,
      'alarmId': '${alarm.id}',
      if (nom.isNotEmpty) 'nom': nom,
      if (dosage.isNotEmpty) 'dosage': dosage,
      if (heure.isNotEmpty) 'heure': heure,
    };
    final uri = Uri(path: '/alarm-ring', queryParameters: q);
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    if (loc == '/alarm-ring') return;
    router.go(uri.toString());
  });
}
