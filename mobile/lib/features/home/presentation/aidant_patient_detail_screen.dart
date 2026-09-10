import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/aidant_models.dart';
import '../domain/constante_models.dart';
import 'widgets/constante_card.dart' show constanteLabel;
import 'widgets/home_skeleton.dart';

class AidantPatientDetailScreen extends ConsumerStatefulWidget {
  const AidantPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patient,
  });

  final String patientId;
  final AidantPatient patient;

  @override
  ConsumerState<AidantPatientDetailScreen> createState() =>
      _AidantPatientDetailScreenState();
}

class _AidantPatientDetailScreenState
    extends ConsumerState<AidantPatientDetailScreen> {
  AidantObservance? _observance;
  List<Constante> _constantes = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final observance = widget.patient.permissions.observance
          ? await ref.read(homeRepositoryProvider).fetchPatientObservance(
                widget.patientId,
              )
          : null;
      final constantes = widget.patient.permissions.constantes
          ? await ref.read(homeRepositoryProvider).listAidantConstantes(
                widget.patientId,
              )
          : const <Constante>[];
      if (!mounted) return;
      setState(() {
        _observance = observance;
        _constantes = constantes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMd(locale);

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
                    title: Text(widget.patient.displayName),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (_loading)
                const ProfilePageSkeleton(rows: 4)
              else if (_error != null)
                PremiumCard(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                    ),
                  ),
                )
              else ...[
                _PatientHero(patient: widget.patient),
                const SizedBox(height: 18),
                Text(
                  l10n.cercleDetailAdherence.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (!widget.patient.permissions.observance)
                  PremiumCard(
                    child: Text(
                      l10n.cerclePermissionLocked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else if (_observance != null)
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cercleAdherenceWindow(
                            dateFmt.format(_observance!.depuis),
                            dateFmt.format(_observance!.jusquA),
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.percent}%',
                                label: l10n.cercleAdherenceRate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.confirmees}',
                                label: l10n.cercleAdherenceConfirmed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.manquees}',
                                label: l10n.cercleAdherenceMissed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.enAttente}',
                                label: l10n.cercleAdherencePending,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  l10n.cercleDetailVitals.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (!widget.patient.permissions.constantes)
                  PremiumCard(
                    child: Text(
                      l10n.cerclePermissionLocked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else if (_constantes.isEmpty)
                  PremiumCard(
                    child: Text(
                      l10n.cercleNoVitals,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _constantes.length; i++) ...[
                          ListTile(
                            leading: Icon(
                              IconsaxPlusLinear.activity,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                            title: Text(
                              constanteLabel(l10n, _constantes[i].type),
                            ),
                            subtitle: Text(
                              dateFmt.format(_constantes[i].mesureAt),
                            ),
                            trailing: Text(
                              _formatConstante(_constantes[i]),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                          if (i < _constantes.length - 1)
                            Divider(height: 1, color: tokens.border),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatConstante(Constante c) {
    if (c.type.isPaired && c.diastolique != null) {
      return '${c.systolique.toInt()}/${c.diastolique!.toInt()} ${c.unite}';
    }
    final digits = c.type.decimals;
    return '${c.systolique.toStringAsFixed(digits)} ${c.unite}';
  }
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({required this.patient});

  final AidantPatient patient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: tokens.isDark ? 0.2 : 0.1,
              ),
            ),
            child: Text(
              patient.initial,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.displayName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: patient.permissions.observance
                          ? l10n.homeAidantsPermObservance
                          : l10n.cerclePermissionLimited,
                    ),
                    if (patient.permissions.constantes)
                      _Chip(label: l10n.homeAidantsPermConstantes),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7FAFC),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: tokens.isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
