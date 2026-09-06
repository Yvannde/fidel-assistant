import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/home_repository.dart';
import '../domain/dashboard_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

class HomeUiState {
  const HomeUiState({
    this.loading = true,
    this.busy = false,
    this.error,
    this.profile,
    this.dashboard,
  });

  final bool loading;
  final bool busy;
  final String? error;
  final HomeProfile? profile;
  final PatientDashboard? dashboard;

  bool get hasPatient => profile?.hasPatientProfile == true;

  HomeUiState copyWith({
    bool? loading,
    bool? busy,
    String? error,
    HomeProfile? profile,
    PatientDashboard? dashboard,
    bool clearError = false,
    bool clearDashboard = false,
  }) {
    return HomeUiState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
      dashboard: clearDashboard ? null : (dashboard ?? this.dashboard),
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

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
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
        dashboard = await _repo.fetchDashboard();
      }
      state = HomeUiState(
        loading: false,
        profile: profile,
        dashboard: dashboard,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
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

  Future<void> confirmPrise(String id) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repo.confirmPrise(id);
      await load();
    } catch (e) {
      state = state.copyWith(
        busy: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      rethrow;
    }
  }

  Future<String> createShareCode() => _repo.createSyncCode();

  Future<String> joinWithCode(String code) => _repo.syncAsAidant(code);
}
