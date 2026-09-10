import '../features/home/domain/dashboard_models.dart';
import 'scheduled_dose.dart';

/// Helpers purs pour limiter le coût réseau / AlarmManager (point perf).
abstract final class ReminderSyncPerf {
  /// Fenêtre de planification locale (préavis + H0 + mark).
  static const scheduleHorizon = Duration(hours: 48);

  /// Jours futurs à fetcher au-delà de J0 (0..2 pour un horizon 48 h).
  static int extraDaysToFetch(
    DateTime now, {
    Duration horizon = scheduleHorizon,
  }) {
    final end = now.add(horizon);
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final days = endDay.difference(today).inDays;
    if (days < 0) return 0;
    if (days > 2) return 2;
    return days;
  }

  /// Dose encore dans la fenêtre à planifier (pas trop passée, ≤ horizon).
  static bool isWithinHorizon(
    DateTime heurePrevue,
    DateTime now, {
    Duration horizon = scheduleHorizon,
    Duration pastGrace = const Duration(minutes: 5),
  }) {
    if (!heurePrevue.isAfter(now.subtract(pastGrace))) return false;
    if (heurePrevue.isAfter(now.add(horizon))) return false;
    return true;
  }

  static List<ScheduledDose> filterHorizon(
    Iterable<ScheduledDose> doses,
    DateTime now, {
    Duration horizon = scheduleHorizon,
  }) {
    return [
      for (final d in doses)
        if (isWithinHorizon(d.heurePrevue, now, horizon: horizon)) d,
    ];
  }

  /// Fingerprint des prises pending du dashboard (skip sync rapide).
  static String dashboardPendingFingerprint(List<PriseDuJour> prises) {
    final map = <String, String>{};
    for (final p in prises) {
      if (!p.isPending) continue;
      map[p.id] = '${p.heurePrevue.toUtc().millisecondsSinceEpoch}';
    }
    return ScheduledDose.globalFingerprint(map);
  }

  /// Fingerprint des doses à planifier (id + heure).
  static String dosesFingerprint(List<ScheduledDose> doses) {
    final map = <String, String>{
      for (final d in doses)
        d.priseId: '${d.heurePrevue.toUtc().millisecondsSinceEpoch}',
    };
    return ScheduledDose.globalFingerprint(map);
  }

  /// Inclut prefs locales qui imposent une replanif même si le dashboard est inchangé.
  static String syncGateKey({
    required String dashboardFingerprint,
    required int preavisMinutes,
    required bool discreet,
    required bool useCustomVoice,
    required String? customVoiceExt,
  }) {
    return '$dashboardFingerprint|p=$preavisMinutes|d=${discreet ? 1 : 0}|'
        'v=${useCustomVoice ? 1 : 0}|e=${customVoiceExt ?? ''}';
  }

  /// Meta voix pour éviter un re-téléchargement inutile.
  static String voixMetaKey({
    required String? id,
    required String? fichierAudioUrl,
    required bool isPersonnalisee,
  }) {
    if (!isPersonnalisee) return 'systeme';
    return 'custom|${id ?? ''}|${fichierAudioUrl ?? ''}';
  }
}
