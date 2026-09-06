import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// 6 cases OTP — focus auto + collage + callback quand le code est complet.
class OtpPinInput extends StatefulWidget {
  const OtpPinInput({
    super.key,
    required this.onCompleted,
    this.enabled = true,
    this.hasError = false,
  });

  final ValueChanged<String> onCompleted;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpPinInput> createState() => OtpPinInputState();
}

class OtpPinInputState extends State<OtpPinInput> {
  static const _len = 6;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _len; i++) {
      final index = i;
      _focusNodes[index].addListener(() {
        if (mounted) setState(() {});
      });
      _focusNodes[index].onKeyEvent = (node, event) => _onKey(index, event);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get code => _controllers.map((c) => c.text).join();

  void clear() {
    _lastEmitted = '';
    for (final c in _controllers) {
      c.clear();
    }
    if (widget.enabled && mounted) {
      _focusNodes[0].requestFocus();
    }
    setState(() {});
  }

  void _emitIfComplete() {
    final value = code;
    if (value.length == _len && value != _lastEmitted) {
      _lastEmitted = value;
      widget.onCompleted(value);
    }
  }

  void _onChanged(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _controllers[index].value = TextEditingValue.empty;
      _lastEmitted = '';
      setState(() {});
      return;
    }

    if (digits.length > 1) {
      var cursor = index;
      for (var j = 0; j < digits.length && cursor < _len; j++) {
        _controllers[cursor].text = digits[j];
        cursor++;
      }
      final focusAt = (cursor >= _len ? _len - 1 : cursor);
      if (cursor >= _len) {
        _focusNodes[focusAt].unfocus();
      } else {
        _focusNodes[focusAt].requestFocus();
      }
      setState(() {});
      _emitIfComplete();
      return;
    }

    if (_controllers[index].text != digits) {
      _controllers[index].text = digits;
    }

    if (index < _len - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    setState(() {});
    _emitIfComplete();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _lastEmitted = '';
      _focusNodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    _lastEmitted = '';
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Code OTP',
      child: Row(
        children: List.generate(_len, (i) {
          final focused = _focusNodes[i].hasFocus;
          final filled = _controllers[i].text.isNotEmpty;
          final borderColor = widget.hasError
              ? scheme.error
              : focused
                  ? AppColors.borderFocus
                  : filled
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : tokens.border;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 5,
                right: i == _len - 1 ? 0 : 5,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 56,
                decoration: BoxDecoration(
                  color: tokens.isDark
                      ? AppColors.surfaceElevatedDark
                      : tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: focused || widget.hasError ? 1.8 : 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: i == _len - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  maxLength: 6,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                  cursorColor: AppColors.primary,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    isDense: true,
                  ),
                  onChanged: (v) => _onChanged(i, v),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
