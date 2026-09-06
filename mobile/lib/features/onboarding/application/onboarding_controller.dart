import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(apiClient: ref.watch(apiClientProvider));
});

class OnboardingUiState {
  const OnboardingUiState({
    this.step = 'infos',
    this.hasPatientProfile = false,
    this.maladies = const [],
    this.maladiesFailed = false,
    this.busy = false,
    this.infos = const InfosDraft(),
    this.besoinActif,
    this.traitement = const TraitementDraft(),
  });

  final String step;
  final bool hasPatientProfile;
  final List<MaladieCatalogItem> maladies;
  final bool maladiesFailed;
  final bool busy;
  final InfosDraft infos;
  final bool? besoinActif;
  final TraitementDraft traitement;

  OnboardingUiState copyWith({
    String? step,
    bool? hasPatientProfile,
    List<MaladieCatalogItem>? maladies,
    bool? maladiesFailed,
    bool? busy,
    InfosDraft? infos,
    bool? besoinActif,
    TraitementDraft? traitement,
    bool clearBesoin = false,
  }) {
    return OnboardingUiState(
      step: step ?? this.step,
      hasPatientProfile: hasPatientProfile ?? this.hasPatientProfile,
      maladies: maladies ?? this.maladies,
      maladiesFailed: maladiesFailed ?? this.maladiesFailed,
      busy: busy ?? this.busy,
      infos: infos ?? this.infos,
      besoinActif: clearBesoin ? null : (besoinActif ?? this.besoinActif),
      traitement: traitement ?? this.traitement,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingUiState>((ref) {
  return OnboardingController(ref);
});

class OnboardingController extends StateNotifier<OnboardingUiState> {
  OnboardingController(this._ref) : super(const OnboardingUiState());

  final Ref _ref;

  OnboardingRepository get _repo => _ref.read(onboardingRepositoryProvider);

  void setInfosDraft(InfosDraft draft) {
    state = state.copyWith(infos: draft);
  }

  void setBesoinDraft(bool? actif) {
    state = state.copyWith(besoinActif: actif, clearBesoin: actif == null);
  }

  void setTraitementDraft(TraitementDraft draft) {
    state = state.copyWith(traitement: draft);
  }

  Future<void> syncFromSessionOrServer() async {
    final session = _ref.read(authSessionProvider);
    if (session != null && session.onboardingStep.isNotEmpty) {
      state = state.copyWith(
        step: session.onboardingStep,
        hasPatientProfile: session.hasPatientProfile,
      );
    }
    try {
      final status = await _repo.status();
      state = state.copyWith(
        step: status.onboardingStep,
        hasPatientProfile: status.hasPatientProfile,
      );
      _ref.read(authSessionProvider.notifier).updateOnboarding(
            step: status.onboardingStep,
            hasPatientProfile: status.hasPatientProfile,
          );
    } catch (_) {
      // Garde le step session si le réseau échoue.
    }
    try {
      final profile = await _repo.fetchProfileDraft();
      final empty = state.infos.nomComplet.trim().isEmpty;
      if (empty && profile.nomComplet.trim().isNotEmpty) {
        state = state.copyWith(infos: profile);
      } else if (empty) {
        state = state.copyWith(
          infos: state.infos.copyWith(
            phone: profile.phone.isNotEmpty ? profile.phone : state.infos.phone,
            localisation: profile.localisation.isNotEmpty
                ? profile.localisation
                : state.infos.localisation,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> saveInfos({
    required String nomComplet,
    required DateTime dateNaissance,
    required String sexe,
    required String localisation,
    String? phone,
  }) async {
    final draft = InfosDraft(
      nomComplet: nomComplet,
      dateNaissance: dateNaissance,
      sexe: sexe,
      localisation: localisation,
      phone: phone ?? '',
    );
    state = state.copyWith(busy: true, infos: draft);
    try {
      final date =
          '${dateNaissance.year.toString().padLeft(4, '0')}-${dateNaissance.month.toString().padLeft(2, '0')}-${dateNaissance.day.toString().padLeft(2, '0')}';
      final step = await _repo.saveInfos(
        nomComplet: nomComplet,
        dateNaissance: date,
        sexe: sexe,
        localisation: localisation,
        phone: phone,
      );
      state = state.copyWith(step: step, busy: false);
      _ref.read(authSessionProvider.notifier).updateOnboarding(step: step);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> setBesoinSuivi({required bool actif}) async {
    state = state.copyWith(busy: true, besoinActif: actif);
    try {
      final result = await _repo.setBesoinSuivi(actif: actif);
      state = state.copyWith(
        step: result.step,
        hasPatientProfile: result.hasPatientProfile,
        busy: false,
      );
      _ref.read(authSessionProvider.notifier).updateOnboarding(
            step: result.step,
            hasPatientProfile: result.hasPatientProfile,
          );
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> loadMaladies({bool force = false}) async {
    if (state.maladies.isNotEmpty && !force) return;
    try {
      final list = await _repo.listMaladies();
      state = state.copyWith(maladies: list, maladiesFailed: false);
    } catch (_) {
      state = state.copyWith(maladiesFailed: true);
      rethrow;
    }
  }

  Future<void> saveTraitement({
    required bool enTraitement,
    List<TraitementSelection>? traitements,
  }) async {
    state = state.copyWith(
      busy: true,
      traitement: state.traitement.copyWith(enTraitement: enTraitement),
    );
    try {
      final step = await _repo.saveTraitement(
        enTraitement: enTraitement,
        traitements: traitements,
      );
      state = state.copyWith(step: step, busy: false);
      _ref.read(authSessionProvider.notifier).updateOnboarding(step: step);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> savePermissions({
    required bool notificationsAccordees,
    required bool batterieExemptee,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final step = await _repo.savePermissions(
        notificationsAccordees: notificationsAccordees,
        batterieExemptee: batterieExemptee,
      );
      state = state.copyWith(step: step, busy: false);
      _ref.read(authSessionProvider.notifier).updateOnboarding(step: step);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> complete() async {
    state = state.copyWith(busy: true);
    try {
      final step = await _repo.complete();
      state = state.copyWith(step: step, busy: false);
      _ref.read(authSessionProvider.notifier).updateOnboarding(step: step);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }
}
