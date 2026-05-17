import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Destek birimi ana ekranı — depremzede ana ekranıyla aynı dock yapısı,
/// merkez butonu S.O.S yerine "Beacon Tarama" (kurtarıcı modu).
class RescuerDashboardScreen extends StatelessWidget {
  const RescuerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TopBar()
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 18),
                  const _Greeting()
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ScanButton(
                            onPressed: () => context.push('/rescuer/scan'),
                          )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.92, 0.92),
                                end: const Offset(1.0, 1.0),
                                duration: 600.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 14),
                          _ArQuickButton(
                            onTap: () => context.push('/rescuer/ar'),
                          ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),
                  ),
                  _QuickDock(
                    onTapChat: () => context.push('/victim/chat'),
                    onTapHealth: () => context.push('/victim/health'),
                    onTapMap: () => context.push('/victim/map'),
                    onTapCheckin: () => context.push('/victim/checkin'),
                    onTapDonation: () => context.push('/victim/donation'),
                  ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
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
          child: const Center(
            child: Icon(
              Icons.medical_services_rounded,
              color: AppColors.textOnPrimary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Yanındayım',
            style: AppTypography.logoTitle(
              fontSize: 26,
              color: AppColors.primaryDeep,
              letterSpacing: -0.6,
            ),
          ),
        ),
        _IconButton(
          icon: Icons.settings_outlined,
          semanticLabel: 'Ayarlar',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
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
          'Sahaya hazırsın.',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primaryDeep,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Çevredeki SOS yayını yapan mağdurları tarayarak haritada görebilirsin.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── scan button ───────────────────────────────

class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
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
    return Semantics(
      button: true,
      label: 'Beacon tarama başlat',
      hint:
          'Yakındaki SOS yayını yapan mağdurları haritada gösterir, kamera ile etrafa baktığında konumlarını canlı işaretler.',
      onTap: widget.onPressed,
      child: AspectRatio(
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
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _ScanRingsPainter(progress: _ring.value),
                    );
                  },
                ),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  heightFactor: 0.72,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primarySoft, AppColors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: AppColors.textOnPrimary,
                          size: 44,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BEACON\nTARAMA',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            height: 1.05,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textOnPrimary
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'enkaz altı tespiti',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textOnPrimary
                                    .withValues(alpha: 0.9),
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanRingsPainter extends CustomPainter {
  _ScanRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = (0.36 + phase * 0.6) * maxRadius;
      final alpha = (1 - phase) * 0.25;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────── bottom dock ───────────────────────────────

class _QuickDock extends StatelessWidget {
  const _QuickDock({
    required this.onTapChat,
    required this.onTapHealth,
    required this.onTapMap,
    required this.onTapCheckin,
    required this.onTapDonation,
  });

  final VoidCallback onTapChat;
  final VoidCallback onTapHealth;
  final VoidCallback onTapMap;
  final VoidCallback onTapCheckin;
  final VoidCallback onTapDonation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DockItem(
            icon: Icons.forum_rounded,
            label: 'Offline AI',
            subtitle: 'Asistan',
            color: AppColors.teal,
            onTap: onTapChat,
          ),
          _DockItem(
            icon: Icons.health_and_safety_rounded,
            label: 'Sağlık',
            subtitle: 'Acil kart',
            color: AppColors.critical,
            onTap: onTapHealth,
          ),
          _DockItem(
            icon: Icons.map_rounded,
            label: 'Toplanma',
            subtitle: 'En yakın',
            color: AppColors.amber,
            onTap: onTapMap,
          ),
          _DockItem(
            icon: Icons.check_circle_rounded,
            label: 'Güvendeyim',
            subtitle: 'Aileme',
            color: AppColors.primary,
            onTap: onTapCheckin,
          ),
          _DockItem(
            icon: Icons.volunteer_activism_rounded,
            label: 'Bağış',
            subtitle: 'Destek ol',
            color: AppColors.amber,
            onTap: onTapDonation,
          ),
        ],
      ),
    );
  }
}

class _ArQuickButton extends StatelessWidget {
  const _ArQuickButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'AR ile etrafta tara',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  const _DockItem({
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
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.label}, ${widget.subtitle}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
