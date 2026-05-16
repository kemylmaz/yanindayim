import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

enum StatusType { info, success, warning, critical }

/// Ekran üstünde sabit duran durum bandı.
/// "Sinyaliniz yayında", "AI hazır" gibi güven veren mesajlar için.
/// Pulse animasyonu nabız ritmiyle gevşek tempoda atar.
class StatusBanner extends StatefulWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusType.info,
    this.pulse = false,
  });

  final String message;
  final StatusType type;
  final bool pulse;

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color dot, Color bg}) _colors() {
    return switch (widget.type) {
      StatusType.info => (dot: AppColors.info, bg: AppColors.primarySurface),
      StatusType.success => (
          dot: AppColors.primaryLight,
          bg: AppColors.primarySurface,
        ),
      StatusType.warning => (dot: AppColors.warning, bg: const Color(0xFFFAF1D6)),
      StatusType.critical => (dot: AppColors.critical, bg: const Color(0xFFF6E1E1)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final scale = widget.pulse
                  ? (1.0 + _controller.value * 0.5)
                  : 1.0;
              final opacity = widget.pulse
                  ? (1.0 - _controller.value * 0.5)
                  : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.pulse)
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.dot.withValues(alpha: opacity * 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
