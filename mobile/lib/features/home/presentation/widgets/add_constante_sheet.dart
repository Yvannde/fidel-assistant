import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/premium.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/home_controller.dart';
import '../../domain/constante_models.dart';
import 'constante_card.dart' show constanteLabel;

/// Saisie d’une mesure — `POST /patients/me/constantes`.
/// Le message affiché ensuite est celui renvoyé par le backend.
abstract final class AddConstanteSheet {
  static Future<void> show(BuildContext context, {ConstanteType? initial}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddConstanteBody(initial: initial),
    );
  }
}

class _AddConstanteBody extends ConsumerStatefulWidget {
  const _AddConstanteBody({this.initial});

  final ConstanteType? initial;

  @override
  ConsumerState<_AddConstanteBody> createState() => _AddConstanteBodyState();
}

class _AddConstanteBodyState extends ConsumerState<_AddConstanteBody> {
  late ConstanteType _type = widget.initial ?? ConstanteType.poids;
  late String _unit = _type.defaultUnit;

  final _value = TextEditingController();
  final _diastolic = TextEditingController();

  DateTime _measuredAt = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    _diastolic.dispose();
    super.dispose();
  }

  void _selectType(ConstanteType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _unit = type.defaultUnit;
      _value.clear();
      _diastolic.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.isDark ? tokens.elevated : Colors.white,
              borderRadius: BorderRadius.circular(Premium.radius),
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.addVitalTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in ConstanteType.values)
                        _Chip(
                          label: constanteLabel(l10n, type),
                          selected: type == _type,
                          onTap: () => _selectType(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_type.isPaired)
                    Row(
                      children: [
                        Expanded(
                          child: _numberField(
                            controller: _value,
                            label: l10n.addVitalSystolic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numberField(
                            controller: _diastolic,
                            label: l10n.addVitalDiastolic,
                          ),
                        ),
                      ],
                    )
                  else
                    _numberField(
                      controller: _value,
                      label: l10n.addVitalValue,
                      suffix: _type.units.length == 1 ? _unit : null,
                    ),
                  if (_type.units.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final unit in _type.units) ...[
                          _Chip(
                            label: unit,
                            selected: unit == _unit,
                            onTap: () => setState(() => _unit = unit),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DateRow(
                    label: l10n.addVitalDate,
                    value: DateFormat.yMMMMd(locale).format(_measuredAt),
                    onTap: _pickDate,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.addVitalSave),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _measuredAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final first = _parse(_value);
    final second = _type.isPaired ? _parse(_diastolic) : null;

    if (first == null || (_type.isPaired && second == null)) {
      setState(() => _error = l10n.addVitalInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = _type.isPaired ? '$first/$second' : first;

    try {
      final created = await ref.read(homeControllerProvider.notifier).addConstante(
            type: _type,
            valeur: payload,
            unite: _unit,
            mesureAt: _measuredAt,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      // Le backend renvoie un message pédagogique en français uniquement.
      final french = Localizations.localeOf(context).languageCode == 'fr';
      AppToast.success(
        context,
        french && created.message.isNotEmpty
            ? created.message
            : l10n.homeVitalsSaved,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ApiException ? e.message : l10n.genericError;
      });
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Material(
      color: selected
          ? AppColors.primary
          : (tokens.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F9)),
      borderRadius: BorderRadius.circular(Premium.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final radius = BorderRadius.circular(Premium.radiusSm);

    return Material(
      color: tokens.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF4F7FB),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                IconsaxPlusLinear.calendar_1,
                size: 16,
                color: tokens.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
