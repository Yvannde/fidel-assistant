import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_providers.dart';
import '../data/home_repository.dart';
import '../domain/aidant_models.dart';
import 'home_controller.dart';

class CercleUiState {
  const CercleUiState({
    this.accompaniedPatients = const [],
    this.aidants = const [],
    this.contactsCount = 0,
    this.loading = false,
    this.busy = false,
    this.error,
    this.sosTicket,
    this.hasPatient = false,
    this.isAidant = false,
    this.loadedOnce = false,
  });

  final List<AidantPatient> accompaniedPatients;
  final List<AidantRelation> aidants;
  final int contactsCount;
  final bool loading;
  final bool busy;
  final String? error;
  final SosTicket? sosTicket;

  /// Capacités résolues (session ∪ profil home) — source pour l’UI.
  final bool hasPatient;
  final bool isAidant;
  final bool loadedOnce;

  bool get hasContacts => contactsCount > 0;

  CercleUiState copyWith({
    List<AidantPatient>? accompaniedPatients,
    List<AidantRelation>? aidants,
    int? contactsCount,
    bool? loading,
    bool? busy,
    String? error,
    SosTicket? sosTicket,
    bool? hasPatient,
    bool? isAidant,
    bool? loadedOnce,
    bool clearError = false,
    bool clearSos = false,
  }) {
    return CercleUiState(
      accompaniedPatients: accompaniedPatients ?? this.accompaniedPatients,
      aidants: aidants ?? this.aidants,
      contactsCount: contactsCount ?? this.contactsCount,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      sosTicket: clearSos ? null : (sosTicket ?? this.sosTicket),
      hasPatient: hasPatient ?? this.hasPatient,
      isAidant: isAidant ?? this.isAidant,
      loadedOnce: loadedOnce ?? this.loadedOnce,
    );
  }
}

class CercleController extends StateNotifier<CercleUiState> {
  CercleController(this._ref) : super(const CercleUiState());

  final Ref _ref;
  int _loadGen = 0;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);

  ({bool hasPatient, bool isAidant}) _caps() {
    final profile = _ref.read(homeControllerProvider).profile;
    final session = _ref.read(authSessionProvider);
    return (
      hasPatient: profile?.hasPatientProfile == true ||
          session?.hasPatientProfile == true,
      isAidant: profile?.isAidant == true || session?.isAidant == true,
    );
  }

  /// Attend jusqu’à ~2 s que le profil home soit peuplé (boot / hot restart).
  Future<void> _waitForHomeProfile() async {
    for (var i = 0; i < 8; i++) {
      final home = _ref.read(homeControllerProvider);
      if (home.profile != null) return;
      if (!home.loading && home.profile == null && i >= 3) {
        // Home a fini sans profil → on continue avec la session.
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> load({bool force = false}) async {
    final gen = ++_loadGen;
    state = state.copyWith(loading: true, clearError: true);

    await _waitForHomeProfile();
    if (gen != _loadGen) return;

    final caps = _caps();
    state = state.copyWith(
      hasPatient: caps.hasPatient,
      isAidant: caps.isAidant,
    );

    if (!caps.hasPatient && !caps.isAidant) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        accompaniedPatients: const [],
        aidants: const [],
        contactsCount: 0,
      );
      return;
    }

    try {
      final futures = await Future.wait([
        caps.isAidant
            ? _repo.listAccompaniedPatients()
            : Future.value(const <AidantPatient>[]),
        caps.hasPatient
            ? _repo.listAidants()
            : Future.value(const <AidantRelation>[]),
        caps.hasPatient
            ? _repo.listContactsUrgence()
            : Future.value(const []),
      ]);
      if (!mounted || gen != _loadGen) return;
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        hasPatient: caps.hasPatient,
        isAidant: caps.isAidant,
        accompaniedPatients: futures[0] as List<AidantPatient>,
        aidants: futures[1] as List<AidantRelation>,
        contactsCount: futures[2].length,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || gen != _loadGen) return;
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<SosTicket> triggerSos() async {
    state = state.copyWith(busy: true, clearError: true, clearSos: true);
    try {
      final ticket = await _repo.triggerSos();
      state = state.copyWith(busy: false, sosTicket: ticket);
      return ticket;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<String> cancelSos(String sosId) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final msg = await _repo.cancelSos(sosId);
      state = state.copyWith(busy: false, clearSos: true);
      return msg;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  void clearSosState() {
    state = state.copyWith(clearSos: true);
  }
}

/// KeepAlive : IndexedStack garde l’onglet monté, mais on évite de perdre
/// l’état au moindre unwatch.
final cercleControllerProvider =
    StateNotifierProvider<CercleController, CercleUiState>((ref) {
  return CercleController(ref);
});
