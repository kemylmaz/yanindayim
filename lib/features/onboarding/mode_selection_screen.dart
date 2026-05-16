import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/user_mode.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key, this.onModeSelected});

  final void Function(UserMode mode)? onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          const _OrbitingBlobs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(child: _Hero()),
                  ),
                  const SizedBox(height: 8),
                  _SwipeTile(
                    mode: UserMode.victim,
                    direction: SwipeDirection.right,
                    icon: Icons.front_hand_rounded,
                    background: AppColors.primary,
                    foreground: AppColors.textOnPrimary,
                    handleBackground: AppColors.textOnPrimary,
                    handleForeground: AppColors.primaryDeep,
                    onConfirmed: () =>
                        onModeSelected?.call(UserMode.victim),
                  ).animate(delay: 350.ms).fadeIn(duration: 500.ms).moveY(
                        begin: 16,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 18),
                  _SwipeTile(
                    mode: UserMode.rescuer,
                    direction: SwipeDirection.left,
                    icon: Icons.medical_services_rounded,
                    background: AppColors.surface,
                    foreground: AppColors.primaryDeep,
                    handleBackground: AppColors.primary,
                    handleForeground: AppColors.textOnPrimary,
                    onConfirmed: () =>
                        onModeSelected?.call(UserMode.rescuer),
                  ).animate(delay: 500.ms).fadeIn(duration: 500.ms).moveY(
                        begin: 16,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Verileriniz sadece bu cihazda kalır.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryDeep.withValues(alpha: 0.65),
                    ),
                  ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── background ────────────────────────────────

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.background,
              AppColors.backgroundBottom,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Tüm sayfayı kaplayan, yavaş yörünge çizen blob animasyonu.
/// Eye-friendly: düşük alpha + yavaş hareket (30 saniyelik döngü).
class _OrbitingBlobs extends StatefulWidget {
  const _OrbitingBlobs();

  @override
  State<_OrbitingBlobs> createState() => _OrbitingBlobsState();
}

class _OrbitingBlobsState extends State<_OrbitingBlobs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrbitPainter(progress: _controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.progress});

  final double progress;

  /// Her blob bir orbit parametre seti içerir:
  /// (radiusFactor, sizeFactor, phase, color, alpha)
  static const _orbits = <_Orbit>[
    _Orbit(
      radiusFactor: 0.42,
      sizeFactor: 0.30,
      phaseOffset: 0.0,
      color: Color(0xFFFFFFFF),
      alpha: 0.10,
    ),
    _Orbit(
      radiusFactor: 0.55,
      sizeFactor: 0.22,
      phaseOffset: 0.33,
      color: Color(0xFF7DD896),
      alpha: 0.18,
    ),
    _Orbit(
      radiusFactor: 0.35,
      sizeFactor: 0.18,
      phaseOffset: 0.66,
      color: Color(0xFFFFFFFF),
      alpha: 0.08,
    ),
    _Orbit(
      radiusFactor: 0.62,
      sizeFactor: 0.26,
      phaseOffset: 0.20,
      color: Color(0xFF42B468),
      alpha: 0.14,
    ),
    _Orbit(
      radiusFactor: 0.48,
      sizeFactor: 0.16,
      phaseOffset: 0.78,
      color: Color(0xFFFFFFFF),
      alpha: 0.07,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);

    for (final orbit in _orbits) {
      final angle = (progress + orbit.phaseOffset) * 2 * math.pi;
      final radius = maxDim * orbit.radiusFactor;
      final blobCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawCircle(
        blobCenter,
        maxDim * orbit.sizeFactor,
        Paint()..color = orbit.color.withValues(alpha: orbit.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Orbit {
  const _Orbit({
    required this.radiusFactor,
    required this.sizeFactor,
    required this.phaseOffset,
    required this.color,
    required this.alpha,
  });

  final double radiusFactor;
  final double sizeFactor;
  final double phaseOffset;
  final Color color;
  final double alpha;
}

// ──────────────────────────────── hero ──────────────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 2× bigger logo (eski 110px → 220px)
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.18),
                ),
              ),
              Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.32),
                ),
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.25),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeep.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(-4, -4),
                    ),
                  ],
                ),
                child: const _PremiumLogo(size: 64),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 18),
        Text(
          'Yanında',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primaryDeep,
            fontSize: 56,
            height: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
      ],
    );
  }
}

class _PremiumLogo extends StatefulWidget {
  const _PremiumLogo({this.size = 64});

  final double size;

  @override
  State<_PremiumLogo> createState() => _PremiumLogoState();
}

class _PremiumLogoState extends State<_PremiumLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing aura
            Container(
              width: widget.size * (1.1 + _pulse.value * 0.15),
              height: widget.size * (1.1 + _pulse.value * 0.15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textOnPrimary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textOnPrimary.withValues(
                      alpha: 0.25 * _pulse.value,
                    ),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.volunteer_activism_rounded,
              size: widget.size * 0.85,
              color: AppColors.textOnPrimary,
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────── swipe tile ────────────────────────────────

enum SwipeDirection { right, left }

class _SwipeTile extends StatefulWidget {
  const _SwipeTile({
    required this.mode,
    required this.direction,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.handleBackground,
    required this.handleForeground,
    required this.onConfirmed,
  });

  final UserMode mode;
  final SwipeDirection direction;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color handleBackground;
  final Color handleForeground;
  final VoidCallback onConfirmed;

  @override
  State<_SwipeTile> createState() => _SwipeTileState();
}

class _SwipeTileState extends State<_SwipeTile>
    with SingleTickerProviderStateMixin {
  static const double _tileHeight = 142; // Increased to fix bottom overflow
  static const double _handleSize = 100; // Increased to match new height properly
  static const double _padding = 8;

  double _drag = 0; // 0..1 (drag progress)
  bool _confirmed = false;

  late final AnimationController _hintController;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxDrag) {
    if (_confirmed) return;
    final delta = widget.direction == SwipeDirection.right
        ? details.delta.dx
        : -details.delta.dx;
    setState(() {
      _drag = ((_drag * maxDrag + delta) / maxDrag).clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_confirmed) return;
    if (_drag >= 0.75) {
      setState(() {
        _drag = 1;
        _confirmed = true;
      });
      Future.delayed(const Duration(milliseconds: 200), widget.onConfirmed);
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxDrag = width - _handleSize - _padding * 2;
        final handleOffset = widget.direction == SwipeDirection.right
            ? _padding + _drag * maxDrag
            : width - _handleSize - _padding - _drag * maxDrag;

        return Container(
          height: _tileHeight,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(28),
            border: widget.background == AppColors.surface
                ? Border.all(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.0),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Label content
              Positioned.fill(
                child: Opacity(
                  opacity: (1.0 - (_drag * 1.5)).clamp(0.0, 1.0),
                  child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.direction == SwipeDirection.right
                        ? _handleSize + _padding + 12
                        : 24,
                    right: widget.direction == SwipeDirection.left
                        ? _handleSize + _padding + 12
                        : 24,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.icon,
                            color: widget.foreground,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.mode.displayName,
                              style: AppTypography.headlineMedium.copyWith(
                                color: widget.foreground,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mode.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: widget.foreground.withValues(alpha: 0.75),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.direction == SwipeDirection.right
                                  ? 'Seçmek için sağa kaydır →'
                                  : '← Seçmek için sola kaydır',
                              style: AppTypography.labelSmall.copyWith(
                                color: widget.foreground.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              // Handle
              Positioned(
                left: handleOffset,
                top: (_tileHeight - _handleSize) / 2,
                child: GestureDetector(
                  onPanUpdate: (d) => _onPanUpdate(d, maxDrag),
                  onPanEnd: _onPanEnd,
                  child: AnimatedBuilder(
                    animation: _hintController,
                    builder: (context, _) {
                      final hintScale = _drag == 0
                          ? 1.0 + math.sin(_hintController.value * 2 * math.pi) * 0.03
                          : 1.0;
                      return Transform.scale(
                        scale: hintScale,
                        child: Container(
                          width: _handleSize,
                          height: _handleSize,
                          decoration: BoxDecoration(
                            color: widget.handleBackground,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowStrong,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.direction == SwipeDirection.right
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            color: widget.handleForeground,
                            size: 34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
