import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class VictimHomeScreen extends StatelessWidget {
  const VictimHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TopBar()
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),
                  const _StatusStrip()
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .moveY(begin: 8, end: 0, duration: 400.ms),
                  const SizedBox(height: 28),
                  const _Greeting()
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 24),
                  _SosButton(onPressed: () => context.push('/victim/sos'))
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 32),
                  _SectionLabel(
                    label: 'HIZLI ERİŞİM',
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(
                    onTapChat: () => context.push('/victim/chat'),
                    onTapPfa: () => context.push('/victim/pfa'),
                    onTapMap: () => context.push('/victim/map'),
                    onTapCheckin: () => context.push('/victim/checkin'),
                  ).animate(delay: 550.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: 28),
                  _DonationBanner(
                    onTap: () => context.push('/victim/donation'),
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
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

// ──────────────────────────────── top bar ───────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _MiniYPainter()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yanında',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mağdur modu',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _IconButton(
          icon: Icons.settings_outlined,
          onTap: () {
            // TODO: Settings ekrani
          },
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primaryDeep, size: 20),
      ),
    );
  }
}

class _MiniYPainter extends CustomPainter {
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

    final leftArm = Path()
      ..moveTo(w * 0.20, h * 0.20)
      ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.5, h * 0.55);
    final rightArm = Path()
      ..moveTo(w * 0.80, h * 0.20)
      ..quadraticBezierTo(w * 0.70, h * 0.42, w * 0.5, h * 0.55);

    canvas.drawPath(leftArm, paint);
    canvas.drawPath(rightArm, paint);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.55),
      Offset(w * 0.5, h * 0.84),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniYPainter oldDelegate) => false;
}

// ──────────────────────────────── status strip ──────────────────────────────

class _StatusStrip extends StatefulWidget {
  const _StatusStrip();

  @override
  State<_StatusStrip> createState() => _StatusStripState();
}

class _StatusStripState extends State<_StatusStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1.0 + _pulse.value * 0.8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight
                            .withValues(alpha: 0.5 * (1 - _pulse.value)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sistem hazır',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Beacon bekleme modunda · Konum biliniyor',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── greeting ──────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şu an güvendesin.',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primaryDeep,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acil bir durum olursa aşağıdaki düğmeye bas. Hazırım.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── SOS button ────────────────────────────────

class _SosButton extends StatefulWidget {
  const _SosButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding rings (subtle warning)
              AnimatedBuilder(
                animation: _ring,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _SosRingsPainter(progress: _ring.value),
                  );
                },
              ),
              // Main button
              FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 0.72,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD15B5B), AppColors.critical],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.critical.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: AppColors.textOnPrimary,
                        size: 38,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SOS',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'basıp tut',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textOnPrimary
                              .withValues(alpha: 0.85),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosRingsPainter extends CustomPainter {
  _SosRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = (0.36 + phase * 0.6) * maxRadius;
      final alpha = (1 - phase) * 0.22;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.critical.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SosRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────── quick actions ─────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 28, height: 2, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onTapChat,
    required this.onTapPfa,
    required this.onTapMap,
    required this.onTapCheckin,
  });

  final VoidCallback onTapChat;
  final VoidCallback onTapPfa;
  final VoidCallback onTapMap;
  final VoidCallback onTapCheckin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.forum_rounded,
                label: 'AI Sohbet',
                subtitle: 'Offline asistan',
                color: AppColors.teal,
                onTap: onTapChat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.spa_rounded,
                label: 'PFA',
                subtitle: 'Sakinleşme',
                color: AppColors.primarySoft,
                onTap: onTapPfa,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.map_rounded,
                label: 'Toplanma',
                subtitle: 'En yakın alan',
                color: AppColors.amber,
                onTap: onTapMap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.check_circle_rounded,
                label: 'Güvendeyim',
                subtitle: 'Aileme bildir',
                color: AppColors.primary,
                onTap: onTapCheckin,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                widget.label,
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 17,
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
      ),
    );
  }
}

// ──────────────────────────────── donation banner ───────────────────────────

class _DonationBanner extends StatelessWidget {
  const _DonationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.15),
              AppColors.amberSoft.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bağışla destek ol',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'AKUT, Kızılay, AHBAP ve İhtiyaç Haritası',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnAmber.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textOnAmber,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
