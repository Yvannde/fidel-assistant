import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/home_repository.dart';
import '../domain/aidant_models.dart';
import 'home_controller.dart';

class AidantsUiState {
  const AidantsUiState({
    this.aidants = const [],
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final List<AidantRelation> aidants;
  final bool loading;
  final bool busy;
  final String? error;

  AidantsUiState copyWith({
    List<AidantRelation>? aidants,
    bool? loading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return AidantsUiState(
      aidants: aidants ?? this.aidants,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AidantsController extends StateNotifier<AidantsUiState> {
  AidantsController(this._ref) : super(const AidantsUiState());

  final Ref _ref;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final rows = await _repo.listAidants();
      state = state.copyWith(loading: false, aidants: rows);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> updatePermissions({
    required String aidantId,
    required AidantPermissions permissions,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated = await _repo.updateAidantPermissions(
        aidantId: aidantId,
        permissions: permissions,
      );
      final next = [
        for (final a in state.aidants)
          if (a.id == aidantId) updated else a,
      ];
      state = state.copyWith(busy: false, aidants: next);
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<String> revoke(String aidantId) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final msg = await _repo.revokeAidant(aidantId);
      state = state.copyWith(
        busy: false,
        aidants: [
          for (final a in state.aidants)
            if (a.id != aidantId) a,
        ],
      );
      return msg;
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<String> createInviteCode() => _repo.createSyncCode();
}

final aidantsControllerProvider =
    StateNotifierProvider.autoDispose<AidantsController, AidantsUiState>((ref) {
  return AidantsController(ref);
});
