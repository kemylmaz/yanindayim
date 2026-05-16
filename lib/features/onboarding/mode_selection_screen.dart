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
          const _AnimatedPulses(),
          const _BottomBlob(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(child: _Hero()),
                  ),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 2,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'BAŞLAYALIM',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                        Text(
                          'Hangi roldesin?',
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.primaryDeep,
                          ),
                        ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                        const SizedBox(height: 18),
                        _ActionTile(
                          mode: UserMode.victim,
                          color: AppColors.primary,
                          colorSoft: AppColors.primarySoft,
                          icon: Icons.shield_rounded,
                          subtitle: 'Deprem anında yanındayım',
                          onTap: () => onModeSelected?.call(UserMode.victim),
                        ).animate(delay: 450.ms).fadeIn(duration: 500.ms).moveX(
                              begin: -16,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 14),
                        _ActionTile(
                          mode: UserMode.rescuer,
                          color: AppColors.rescuer,
                          colorSoft: AppColors.rescuerLight,
                          icon: Icons.medical_services_rounded,
                          subtitle: 'Yaralılara ulaşmaya geldim',
                          onTap: () => onModeSelected?.call(UserMode.rescuer),
                        ).animate(delay: 600.ms).fadeIn(duration: 500.ms).moveX(
                              begin: -16,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                  Text(
                    'Verileriniz sadece bu cihazda kalır.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BottomBlob extends StatelessWidget {
  const _BottomBlob();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -100,
      left: -80,
      child: IgnorePointer(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

/// Sağ üstten yayılan seismic-wave benzeri pulse halkaları.
/// Sürekli loop, sahnenin ritmini canlandırır ama dikkat dağıtmaz.
class _AnimatedPulses extends StatefulWidget {
  const _AnimatedPulses();

  @override
  State<_AnimatedPulses> createState() => _AnimatedPulsesState();
}

class _AnimatedPulsesState extends State<_AnimatedPulses>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _PulsePainter(progress: _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress});

  final double progress;

  static const _ringCount = 4;
  static const _maxAlpha = 0.32;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 1.05, size.height * 0.04);
    final maxRadius = size.width * 0.95;

    for (var i = 0; i < _ringCount; i++) {
      final phase = (progress + i / _ringCount) % 1.0;
      final radius = phase * maxRadius;
      if (radius < 4) continue;

      final fade = 1.0 - phase;
      final alpha = _maxAlpha * fade * fade;

      final color = i.isEven ? AppColors.primary : AppColors.amber;

      canvas.drawCircle(
        origin,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Anchor dot at origin (slight glow)
    canvas.drawCircle(
      origin,
      6,
      Paint()..color = AppColors.primary.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────── hero ──────────────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                ),
              ),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft.withValues(alpha: 0.7),
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeep.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const _YMonogram(size: 32),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 22),
        Text(
          'Yanında',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primaryDeep,
            height: 1.0,
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
        const SizedBox(height: 10),
        SizedBox(
          width: 280,
          child: Text(
            'Deprem anında ve sonrasında — internet olmadan da.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
      ],
    );
  }
}


// ──────────────────────────────── logo monogram ─────────────────────────────

/// "Y" monogram — Yanında harfi + kollarını açmış bir kişi figürü.
/// İki kavisli kol = sarmalayan kollar; gövde = dik duruş.
class _YMonogram extends StatelessWidget {
  const _YMonogram({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _YMonogramPainter()),
    );
  }
}

class _YMonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = AppColors.textOnPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sol kol (kavisli)
    final leftArm = Path()
      ..moveTo(w * 0.20, h * 0.20)
      ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.5, h * 0.55);

    // Sağ kol (kavisli, simetrik)
    final rightArm = Path()
      ..moveTo(w * 0.80, h * 0.20)
      ..quadraticBezierTo(w * 0.70, h * 0.42, w * 0.5, h * 0.55);

    canvas.drawPath(leftArm, paint);
    canvas.drawPath(rightArm, paint);

    // Gövde (dikey)
    canvas.drawLine(
      Offset(w * 0.5, h * 0.55),
      Offset(w * 0.5, h * 0.84),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _YMonogramPainter oldDelegate) => false;
}

// ──────────────────────────────── action tile ───────────────────────────────

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.mode,
    required this.color,
    required this.colorSoft,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  final UserMode mode;
  final Color color;
  final Color colorSoft;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.colorSoft, widget.color],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.textOnPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.mode.displayName,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textOnPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
