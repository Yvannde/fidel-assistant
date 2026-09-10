import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../../services/reminder_sync.dart';
import '../../../services/sync_engine.dart';
import '../../../services/sync_outbox.dart';
import '../data/home_repository.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';
import 'home_projection.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

/// Onglet du shell accueil — Accueil, Soins, Proches, Toi.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

DateTime homeDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool homeSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String homeDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Lundi de la semaine contenant [d].
DateTime homeWeekStart(DateTime d) {
  final day = homeDateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

class HomeUiState {
  const HomeUiState({
    this.loading = true,
    this.busy = false,
    this.error,
    this.profile,
    this.dashboard,
    this.selectedDay,
    this.dayPrises,
    this.weekDays = const {},
    this.weekLoading = false,
    this.traitementDetails = const {},
    this.todayCheckIn,
    this.checkInKnown = false,
    this.checkInBusy = false,
    this.constantes = const [],
    this.constantesKnown = false,
  });

  final bool loading;
  final bool busy;
  final String? error;
  final HomeProfile? profile;
  final PatientDashboard? dashboard;
  final DateTime? selectedDay;
  final List<PriseDuJour>? dayPrises;

  /// Observance agrégée localement, clé `YYYY-MM-DD`. Aujourd’hui exclu :
  /// il est recalculé depuis le dashboard pour rester à jour après confirmation.
  final Map<String, DayAdherence> weekDays;
  final bool weekLoading;

  /// `date_fin_prevue` par traitement — absent du dashboard.
  final Map<String, TraitementDetail> traitementDetails;

  final CheckInEntry? todayCheckIn;
  final bool checkInKnown;
  final bool checkInBusy;

  /// Mesures des 30 derniers jours, tous types confondus.
  final List<Constante> constantes;
  final bool constantesKnown;

  List<ConstanteSeries> get constanteSeries =>
      ConstanteSeries.group(constantes);

  bool get hasPatient => profile?.hasPatientProfile == true;

  DateTime get day => homeDateOnly(selectedDay ?? DateTime.now());

  bool get isTodaySelected => homeSameDay(day, DateTime.now());

  List<PriseDuJour> get visiblePrises {
    if (!isTodaySelected && dayPrises != null) return dayPrises!;
    return dashboard?.prisesAujourdhui ?? const [];
  }

  PatientDashboard? get dashboardForDay {
    final d = dashboard;
    if (d == null) return null;
    if (isTodaySelected) return d;
    return PatientDashboard(
      prochaineAction: 'aucune',
      medicamentsConfigures: d.medicamentsConfigures,
      notificationsAccordees: d.notificationsAccordees,
      traitements: d.traitements,
      prisesAujourdhui: visiblePrises,
    );
  }

  /// Les 7 jours lundi → dimanche, aujourd’hui recalculé en direct.
  List<DayAdherence> get week {
    final today = homeDateOnly(DateTime.now());
    final start = homeWeekStart(today);
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = start.add(Duration(days: i));
          if (homeSameDay(d, today)) {
            return DayAdherence.fromPrises(
              d,
              dashboard?.prisesAujourdhui ?? const [],
            );
          }
          return weekDays[homeDayKey(d)] ?? DayAdherence.empty(d);
        }(),
    ];
  }

  bool get needsCheckIn => checkInKnown && todayCheckIn == null;

  HomeUiState copyWith({
    bool? loading,
    bool? busy,
    String? error,
    HomeProfile? profile,
    PatientDashboard? dashboard,
    DateTime? selectedDay,
    List<PriseDuJour>? dayPrises,
    Map<String, DayAdherence>? weekDays,
    bool? weekLoading,
    Map<String, TraitementDetail>? traitementDetails,
    CheckInEntry? todayCheckIn,
    bool? checkInKnown,
    bool? checkInBusy,
    List<Constante>? constantes,
    bool? constantesKnown,
    bool clearError = false,
    bool clearDashboard = false,
    bool clearDayPrises = false,
    bool clearCheckIn = false,
  }) {
    return HomeUiState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
      dashboard: clearDashboard ? null : (dashboard ?? this.dashboard),
      selectedDay: selectedDay ?? this.selectedDay,
      dayPrises: clearDayPrises ? null : (dayPrises ?? this.dayPrises),
      weekDays: weekDays ?? this.weekDays,
      weekLoading: weekLoading ?? this.weekLoading,
      traitementDetails: traitementDetails ?? this.traitementDetails,
      todayCheckIn: clearCheckIn ? null : (todayCheckIn ?? this.todayCheckIn),
      checkInKnown: checkInKnown ?? this.checkInKnown,
      checkInBusy: checkInBusy ?? this.checkInBusy,
      constantes: constantes ?? this.constantes,
      constantesKnown: constantesKnown ?? this.constantesKnown,
    );
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeUiState>((ref) {
  return HomeController(ref);
});

class HomeController extends StateNotifier<HomeUiState> {
  HomeController(this._ref) : super(const HomeUiState());

  final Ref _ref;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);
  AppDatabase get _db => _ref.read(appDatabaseProvider);
  SyncOutbox get _outbox => _ref.read(syncOutboxProvider);
  SyncEngine get _engine => _ref.read(syncEngineProvider);

  Future<PatientDashboard?> _projectFromLocal() async {
    final base = await _db.readDashboardMeta();
    if (base == null) return null;
    final pending = await _outbox.listPendingForProjection();
    return HomeProjection.projectDashboard(base: base, outbox: pending);
  }

  Future<void> _applyProjectedDashboard(PatientDashboard dashboard) async {
    state = state.copyWith(
      loading: false,
      dashboard: dashboard,
      selectedDay: homeDateOnly(DateTime.now()),
      clearDayPrises: true,
      clearError: true,
    );
  }

  Future<void> reloadProjection() async {
    final projected = await _projectFromLocal();
    if (projected == null || !mounted) return;
    await _applyProjectedDashboard(projected);
    unawaited(syncRemindersFromHome(_ref.read, projected));
  }

  Future<void> load({bool secondary = true}) async {
    state = state.copyWith(loading: true, clearError: true);

    // Hydrate locale d’abord (offline-first).
    try {
      final local = await _projectFromLocal();
      if (local != null && mounted) {
        await _applyProjectedDashboard(local);
      }
    } catch (_) {}

    try {
      final profile = await _repo.fetchProfile();
      final session = _ref.read(authSessionProvider);
      if (session != null) {
        _ref.read(authSessionProvider.notifier).updateOnboarding(
              step: session.onboardingStep,
              hasPatientProfile: profile.hasPatientProfile,
            );
      }
      PatientDashboard? dashboard;
      if (profile.hasPatientProfile) {
        final fetched = await _repo.fetchDashboard();
        if (fetched != null) {
          await _db.upsertDashboard(fetched);
          final pending = await _outbox.listPendingForProjection();
          dashboard = HomeProjection.projectDashboard(
            base: fetched,
            outbox: pending,
          );
        }
      }
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        profile: profile,
        dashboard: dashboard,
        selectedDay: homeDateOnly(DateTime.now()),
        clearDashboard: dashboard == null,
        clearDayPrises: true,
        clearError: true,
      );
      if (dashboard != null) {
        unawaited(syncRemindersFromHome(_ref.read, dashboard));
      }
      if (secondary && dashboard != null) {
        unawaited(_loadSecondary());
      }
    } catch (e) {
      // Garde la projection locale si présente.
      if (state.dashboard != null) {
        state = state.copyWith(loading: false, clearError: true);
        return;
      }
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  /// Semaine, traitements et check-in — jamais bloquants, jamais d’erreur
  /// affichée : l’accueil doit rester lisible sur un réseau faible.
  Future<void> _loadSecondary() async {
    state = state.copyWith(weekLoading: true);
    await Future.wait([
      _loadWeek(),
      _loadTraitements(),
      _loadCheckIn(),
      _loadConstantes(),
    ]);
  }

  static const _constantesWindow = Duration(days: 30);

  Future<void> _loadConstantes() async {
    try {
      final values = await _repo.listConstantes(
        depuis: DateTime.now().subtract(_constantesWindow),
      );
      if (!mounted) return;
      state = state.copyWith(constantes: values, constantesKnown: true);
    } catch (_) {
      // Le suivi des constantes est secondaire : on masque la carte.
    }
  }

  Future<ConstanteCreated> addConstante({
    required ConstanteType type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final created = await _repo.createConstante(
        type: type,
        valeur: valeur,
        unite: unite,
        mesureAt: mesureAt,
      );
      state = state.copyWith(busy: false);
      await _loadConstantes();
      return created;
    } catch (e) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> _loadWeek() async {
    final today = homeDateOnly(DateTime.now());
    final start = homeWeekStart(today);
    final targets = [
      for (var i = 0; i < 7; i++) start.add(Duration(days: i)),
    ].where((d) => d.isBefore(today)).toList();

    if (targets.isEmpty) {
      state = state.copyWith(weekLoading: false);
      return;
    }

    final results = await Future.wait(
      targets.map((d) async {
        try {
          return MapEntry(homeDayKey(d), DayAdherence.fromPrises(
            d,
            await _repo.listPrises(date: d),
          ));
        } catch (_) {
          return null;
        }
      }),
    );

    final merged = Map<String, DayAdherence>.from(state.weekDays);
    for (final entry in results) {
      if (entry != null) merged[entry.key] = entry.value;
    }
    if (!mounted) return;
    state = state.copyWith(weekDays: merged, weekLoading: false);
  }

  Future<void> _loadTraitements() async {
    try {
      final details = await _repo.listTraitements();
      await _db.upsertTraitements(details);
      if (!mounted) return;
      state = state.copyWith(
        traitementDetails: {for (final t in details) t.id: t},
      );
    } catch (_) {
      try {
        final cached = await _db.readTraitementDetails();
        if (cached.isNotEmpty && mounted) {
          state = state.copyWith(traitementDetails: cached);
        }
      } catch (_) {}
    }
  }

  Future<void> _loadCheckIn() async {
    final today = homeDateOnly(DateTime.now());
    try {
      final entries = await _repo.listCheckIns(depuis: today);
      if (!mounted) return;
      CheckInEntry? todays;
      for (final e in entries) {
        if (homeSameDay(e.date, today)) todays = e;
      }
      state = state.copyWith(
        todayCheckIn: todays,
        checkInKnown: true,
        clearCheckIn: todays == null,
      );
    } catch (_) {
      // Sans réponse, on n’affiche pas la carte plutôt que d’en proposer deux.
    }
  }

  Future<void> submitCheckIn(String statut) async {
    state = state.copyWith(checkInBusy: true, clearError: true);
    try {
      final entry = await _repo.submitCheckIn(statut);
      state = state.copyWith(
        checkInBusy: false,
        todayCheckIn: entry,
        checkInKnown: true,
      );
    } catch (e) {
      state = state.copyWith(checkInBusy: false);
      if (e is ApiException && e.code == 'CHECK_IN_DEJA_FAIT_AUJOURDHUI') {
        await _loadCheckIn();
        return;
      }
      rethrow;
    }
  }

  Future<void> activateFollowUp() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repo.activatePatient();
      await load();
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateProfile(HomeProfile profile) async {
    state = state.copyWith(profile: profile);
  }

  Future<void> confirmPrise(String id) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        await _db.updatePriseLocal(id: id, statut: 'confirmee');
        await _engine.enqueueConfirm(priseId: id);
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<void> reportPrise(String id, DateTime nouvelleHeure) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _db.transaction(() async {
        await _db.updatePriseLocal(
          id: id,
          heurePrevue: nouvelleHeure,
          statut: 'en_attente',
        );
        await _engine.enqueueReport(priseId: id, nouvelleHeure: nouvelleHeure);
      });
      await reloadProjection();
      state = state.copyWith(busy: false);
      unawaited(_engine.flush(force: true));
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<void> selectDay(DateTime day) async {
    final d = homeDateOnly(day);
    if (homeSameDay(d, state.day)) return;
    if (homeSameDay(d, DateTime.now())) {
      state = state.copyWith(selectedDay: d, clearDayPrises: true);
      return;
    }
    state = state.copyWith(selectedDay: d, busy: true, clearError: true);
    try {
      final local = await _db.listPrisesForDate(homeDayKey(d));
      final pending = await _outbox.listPendingForProjection();
      final projected = HomeProjection.applyOutbox(
        snapshot: local,
        outbox: pending,
      );
      if (projected.isNotEmpty && mounted) {
        state = state.copyWith(busy: false, dayPrises: projected);
      }
      final prises = await _repo.listPrises(date: d);
      await _db.upsertPrises(prises);
      final pending2 = await _outbox.listPendingForProjection();
      final merged = HomeProjection.applyOutbox(
        snapshot: prises,
        outbox: pending2,
      );
      if (!mounted) return;
      state = state.copyWith(busy: false, dayPrises: merged);
    } catch (e) {
      if (state.dayPrises != null) {
        state = state.copyWith(busy: false);
        return;
      }
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<String> createShareCode() => _repo.createSyncCode();

  Future<String> joinWithCode(String code) => _repo.syncAsAidant(code);
}
