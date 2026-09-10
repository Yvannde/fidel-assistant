import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
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
  });

  final List<AidantPatient> accompaniedPatients;
  final List<AidantRelation> aidants;
  final int contactsCount;
  final bool loading;
  final bool busy;
  final String? error;
  final SosTicket? sosTicket;

  bool get hasContacts => contactsCount > 0;

  CercleUiState copyWith({
    List<AidantPatient>? accompaniedPatients,
    List<AidantRelation>? aidants,
    int? contactsCount,
    bool? loading,
    bool? busy,
    String? error,
    SosTicket? sosTicket,
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
    );
  }
}

class CercleController extends StateNotifier<CercleUiState> {
  CercleController(this._ref) : super(const CercleUiState());

  final Ref _ref;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);

  Future<void> load() async {
    final profile = _ref.read(homeControllerProvider).profile;
    final hasPatient = profile?.hasPatientProfile == true;
    final isAidant = profile?.isAidant == true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final futures = await Future.wait([
        isAidant
            ? _repo.listAccompaniedPatients()
            : Future.value(const <AidantPatient>[]),
        hasPatient ? _repo.listAidants() : Future.value(const <AidantRelation>[]),
        hasPatient
            ? _repo.listContactsUrgence()
            : Future.value(const []),
      ]);
      state = state.copyWith(
        loading: false,
        accompaniedPatients: futures[0] as List<AidantPatient>,
        aidants: futures[1] as List<AidantRelation>,
        contactsCount: futures[2].length,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
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

final cercleControllerProvider =
    StateNotifierProvider.autoDispose<CercleController, CercleUiState>((ref) {
      return CercleController(ref);
    });
