import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';

/// Résultat d’un enregistrement micro (fichier m4a prêt à uploader).
class VoixRecordingResult {
  const VoixRecordingResult({
    required this.path,
    required this.filename,
    required this.bytesLength,
  });

  final String path;
  final String filename;
  final int bytesLength;
}

/// Bottom sheet : start / stop / envoyer (plafond 60 s).
class ProfileVoixRecordSheet extends StatefulWidget {
  const ProfileVoixRecordSheet({super.key});

  static Future<VoixRecordingResult?> show(BuildContext context) {
    return showModalBottomSheet<VoixRecordingResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileVoixRecordSheet(),
    );
  }

  @override
  State<ProfileVoixRecordSheet> createState() => _ProfileVoixRecordSheetState();
}

class _ProfileVoixRecordSheetState extends State<ProfileVoixRecordSheet> {
  static const _maxSeconds = 60;
  static const _maxBytes = 2 * 1024 * 1024;

  final _recorder = AudioRecorder();
  Timer? _ticker;
  bool _recording = false;
  int _elapsed = 0;
  String? _path;
  int? _bytesLength;
  bool _busy = false;

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<bool> _ensureMic() async {
    final l10n = AppLocalizations.of(context);
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      if (mounted) AppToast.error(context, l10n.profileVoixMicDenied);
      return false;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) AppToast.error(context, l10n.profileVoixMicDenied);
      return false;
    }
    return true;
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureMic()) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'voix_rappel_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _ticker?.cancel();
      setState(() {
        _recording = true;
        _elapsed = 0;
        _path = null;
        _bytesLength = null;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted || !_recording) return;
        final next = _elapsed + 1;
        setState(() => _elapsed = next);
        if (next >= _maxSeconds) {
          await _stop();
        }
      });
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.profileVoixRecordFailed);
    }
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      if (path == null || path.isEmpty) {
        setState(() => _recording = false);
        return;
      }
      final file = File(path);
      final length = await file.length();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _path = path;
        _bytesLength = length;
      });
      if (length > _maxBytes) {
        final l10n = AppLocalizations.of(context);
        AppToast.error(context, l10n.profileVoixTooLarge);
        try {
          await file.delete();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _path = null;
          _bytesLength = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _recording = false);
      AppToast.error(
        context,
        AppLocalizations.of(context).profileVoixRecordFailed,
      );
    }
  }

  void _confirm() {
    final path = _path;
    final len = _bytesLength;
    if (path == null || len == null || len <= 0) return;
    setState(() => _busy = true);
    Navigator.pop(
      context,
      VoixRecordingResult(
        path: path,
        filename: p.basename(path),
        bytesLength: len,
      ),
    );
  }

  Future<void> _reset() async {
    if (_recording) await _stop();
    final old = _path;
    setState(() {
      _path = null;
      _bytesLength = null;
      _elapsed = 0;
    });
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final remaining = (_maxSeconds - _elapsed).clamp(0, _maxSeconds);
    final hasTake = _path != null && !_recording;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(Premium.radius),
          border: Border.all(color: tokens.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                IconsaxPlusLinear.microphone_2,
                size: 36,
                color: _recording ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _recording
                    ? l10n.profileVoixRecording
                    : hasTake
                        ? l10n.profileVoixUseRecording
                        : l10n.profileVoixRecordReady,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _recording
                    ? l10n.profileVoixSecondsLeft(remaining)
                    : hasTake
                        ? '${_elapsed}s · ${((_bytesLength ?? 0) / 1024).toStringAsFixed(0)} Ko'
                        : l10n.profileVoixRecordHint,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                )
              else if (_recording)
                FilledButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.profileVoixStop),
                )
              else if (hasTake) ...[
                FilledButton(
                  onPressed: _confirm,
                  child: Text(l10n.profileVoixUseRecording),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _reset,
                  child: Text(l10n.profileVoixRecordAgain),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: Text(l10n.profileVoixStart),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
