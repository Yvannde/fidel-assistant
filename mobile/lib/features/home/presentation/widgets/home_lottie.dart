import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/premium.dart';

/// Lottie home — lecture forcée via [AnimationController] (fiable hors expressions AE).
class HomeLottie extends StatefulWidget {
  const HomeLottie({
    super.key,
    required this.asset,
    this.size = 168,
    this.fallbackIcon = IconsaxPlusLinear.people,
  });

  final String asset;
  final double size;
  final IconData fallbackIcon;

  @override
  State<HomeLottie> createState() => _HomeLottieState();
}

class _HomeLottieState extends State<HomeLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant HomeLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _failed = false;
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        height: widget.size,
        width: widget.size,
        child: Icon(
          widget.fallbackIcon,
          size: widget.size * 0.4,
          color: AppColors.primary.withValues(alpha: 0.9),
        ),
      );
    }

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Lottie.asset(
        widget.asset,
        controller: _controller,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        frameRate: FrameRate.max,
        onLoaded: (composition) {
          if (!mounted) return;
          _controller
            ..duration = composition.duration
            ..repeat();
        },
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_failed) setState(() => _failed = true);
          });
          return Icon(
            widget.fallbackIcon,
            size: widget.size * 0.4,
            color: AppColors.primary.withValues(alpha: 0.9),
          );
        },
      ),
    );
  }
}
