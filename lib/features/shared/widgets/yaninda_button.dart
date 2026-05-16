import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

enum YanindaButtonVariant { primary, secondary, critical, ghost }

/// Min 60dp dokunma alanı, panik için titreyen elle bile kaçırılmaz boyut.
/// Press sırasında subtle scale animasyonu (200ms) güven hissi verir.
class YanindaButton extends StatefulWidget {
  const YanindaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = YanindaButtonVariant.primary,
    this.icon,
    this.subtitle,
    this.fullWidth = true,
    this.minHeight = 60,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final YanindaButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final double minHeight;

  @override
  State<YanindaButton> createState() => _YanindaButtonState();
}

class _YanindaButtonState extends State<YanindaButton> {
  bool _pressed = false;

  ({Color bg, Color fg, Color? border}) _colors() {
    return switch (widget.variant) {
      YanindaButtonVariant.primary => (
          bg: AppColors.primary,
          fg: AppColors.textOnPrimary,
          border: null,
        ),
      YanindaButtonVariant.secondary => (
          bg: AppColors.surface,
          fg: AppColors.primary,
          border: AppColors.primary,
        ),
      YanindaButtonVariant.critical => (
          bg: AppColors.critical,
          fg: AppColors.textOnPrimary,
          border: null,
        ),
      YanindaButtonVariant.ghost => (
          bg: Colors.transparent,
          fg: AppColors.textPrimary,
          border: AppColors.border,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final disabled = widget.onPressed == null;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          decoration: BoxDecoration(
            color: disabled
                ? colors.bg.withValues(alpha: 0.4)
                : colors.bg,
            borderRadius: BorderRadius.circular(16),
            border: colors.border != null
                ? Border.all(color: colors.border!, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: colors.fg, size: 24),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: AppTypography.buttonLarge.copyWith(color: colors.fg),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.fg.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
