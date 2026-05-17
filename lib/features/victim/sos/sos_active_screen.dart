import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/beacon_broadcast_service.dart';
import '../../../core/services/health_card_service.dart';
import '../../../core/services/lockscreen_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'sos_controller.dart';

class SosActiveScreen extends ConsumerStatefulWidget {
  const SosActiveScreen({super.key});

  @override
  ConsumerState<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends ConsumerState<SosActiveScreen> {
  @override
  void initState() {
    super.initState();
    // SOS süresince ekran açık kalsın.
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Kilit ekranını bypass et — telefon uyandığında kilit açmadan SOS gözüksün.
    LockscreenService.instance.showOverLockscreen();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    LockscreenService.instance.hideOverLockscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = ref.watch(sosControllerProvider);

    // Stopped fazına geçince geri dön.
    ref.listen(sosControllerProvider, (prev, next) {
      if (next.phase == SosPhase.stopped) {
        if (context.canPop()) context.pop();
      }
    });

    // PopScope: kullanıcı yanlışlıkla geri ile çıkmasın.
    return PopScope(
      canPop: sos.phase == SosPhase.stopped,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: switch (sos.phase) {
            SosPhase.countdown => _CountdownView(state: sos),
            SosPhase.active => _ActiveView(state: sos),
            SosPhase.stopped => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────── countdown ─────────────────────────────────

class _CountdownView extends ConsumerWidget {
  const _CountdownView({required this.state});

  final SosState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.critical.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppColors.critical,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACİL DURUM',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'BAŞLAMAYA',
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.7),
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            label: '${state.countdownRemaining} saniye kaldı',
            excludeSemantics: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '${state.countdownRemaining}',
                key: ValueKey(state.countdownRemaining),
                textAlign: TextAlign.center,
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 180,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'saniye sonra düdük başlayacak,\nacil kişilere SMS gönderilecek.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          _CancelButton(
            onTap: () => ref.read(sosControllerProvider.notifier).cancel(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CancelButton extends StatefulWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Vazgeç',
      hint: 'SOS başlatma işlemini iptal eder',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textOnPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              'Vazgeç',
              style: AppTypography.buttonLarge.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ──────────────────────────────── active view ───────────────────────────────

class _ActiveView extends ConsumerStatefulWidget {
  const _ActiveView({required this.state});

  final SosState state;

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final mins = (state.activeElapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (state.activeElapsed % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst bilgi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.critical,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary
                                .withValues(alpha: 0.4 + _pulse.value * 0.6),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CANLI · $mins:$secs',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Merkez pulse + başlık
          Expanded(
            flex: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ActivePulsePainter(progress: _pulse.value),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD15B5B), AppColors.critical],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.critical.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: AppColors.textOnPrimary,
                            size: 56,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          Semantics(
            header: true,
            child: Text(
              'Acil yardım iletiliyor',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Düdük çalıyor. Kurtarıcılar yakındaysa sizi bulabilir.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.75),
            ),
          ),

          const SizedBox(height: 16),

          // Sağlık kart özeti — kurtarıcı SOS ekrandayken kritik bilgileri görür.
          const _HealthCardSnapshot(),

          const SizedBox(height: 12),

          // Erişilebilirlik göstergeleri (titreşim + sesli komut)
          const _AccessibilityStatusRow(),

          const SizedBox(height: 12),

          // Milestone list
          _MilestoneList(milestones: state.milestones),

          const Spacer(),

          // KAPAT butonu (basılı tutarak)
          _StopButton(
            onConfirmed: () =>
                ref.read(sosControllerProvider.notifier).cancel(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// SOS aktifken telefon ekranında her zaman görünür "acil sağlık özeti" —
/// kullanıcı bilinçsiz veya kilit ekranındayken kurtarıcı için kritik veri.
class _HealthCardSnapshot extends ConsumerWidget {
  const _HealthCardSnapshot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(healthCardProvider);
    if (card.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.textOnPrimary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'ACİL SAĞLIK BİLGİSİ',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (card.bloodType != null && card.bloodType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    card.bloodType!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.critical,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (card.fullName.isNotEmpty)
            Text(
              card.fullName,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          if (card.allergies.isNotEmpty)
            _kvRow('Alerji', card.allergies.join(', ')),
          if (card.chronicConditions.isNotEmpty)
            _kvRow('Kronik', card.chronicConditions.join(', ')),
          if (card.medications.isNotEmpty)
            _kvRow('İlaç', card.medications.join(', ')),
          if (card.emergencyContactPhone.isNotEmpty)
            _kvRow(
              'Yakın',
              card.emergencyContactName.isNotEmpty
                  ? '${card.emergencyContactName} ${card.emergencyContactPhone}'
                  : card.emergencyContactPhone,
            ),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/// İşitme + görme engelliler için aktif olan erişilebilirlik özelliklerini
/// görsel olarak gösteren bilgi şeridi. Yakın çevre veya yardımcı bilebilir.
class _AccessibilityStatusRow extends StatelessWidget {
  const _AccessibilityStatusRow();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Erişilebilirlik durumu: Titreşim aktif. Sesli komut dinleniyor.',
      child: Row(
        children: [
          Expanded(
            child: _A11yChip(
              icon: Icons.vibration_rounded,
              label: 'Titreşim',
              sublabel: 'Aktif',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _A11yChip(
              icon: Icons.mic_rounded,
              label: 'Sesli komut',
              sublabel: '"Durdur" de',
            ),
          ),
        ],
      ),
    );
  }
}

class _A11yChip extends StatelessWidget {
  const _A11yChip({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textOnPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  sublabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePulsePainter extends CustomPainter {
  _ActivePulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 4; i++) {
      final phase = (progress + i / 4) % 1.0;
      final radius = (0.28 + phase * 0.72) * maxRadius;
      final alpha = (1 - phase) * 0.35;

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
  bool shouldRepaint(covariant _ActivePulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────── milestones ────────────────────────────────

class _MilestoneList extends ConsumerWidget {
  const _MilestoneList({required this.milestones});

  final Set<SosMilestone> milestones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beaconState = ref.watch(beaconBroadcastStateProvider).valueOrNull;
    final beaconId = beaconState?.beacon?.anonymousId;
    final beaconSubtitle = milestones.contains(SosMilestone.beaconActivated)
        ? (beaconId != null ? 'Anonim ID: $beaconId' : null)
        : 'Geri sayım bitince başlar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          _MilestoneRow(
            label: 'Düdük çalıyor',
            done: milestones.contains(SosMilestone.whistleStarted),
          ),
          const SizedBox(height: 10),
          _MilestoneRow(
            label: 'Beacon yayında',
            done: milestones.contains(SosMilestone.beaconActivated),
            subtitle: beaconSubtitle,
          ),
          const SizedBox(height: 10),
          _MilestoneRow(
            label: 'Acil kişilere SMS gönderildi',
            done: milestones.contains(SosMilestone.smsSent),
            subtitle: milestones.contains(SosMilestone.smsSent)
                ? null
                : '60 saniye sonra otomatik',
          ),
          const SizedBox(height: 10),
          _MilestoneRow(
            label: '112 arandı',
            done: milestones.contains(SosMilestone.emergencyCalled),
            subtitle: milestones.contains(SosMilestone.emergencyCalled)
                ? null
                : '60 saniye sonra otomatik',
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.label,
    required this.done,
    this.subtitle,
  });

  final String label;
  final bool done;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.primaryLight
        : AppColors.textOnPrimary.withValues(alpha: 0.4);

    final semanticLabel = done
        ? '$label, tamamlandı'
        : subtitle != null
            ? '$label, bekliyor, $subtitle'
            : '$label, bekliyor';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done
                ? AppColors.primaryLight.withValues(alpha: 0.2)
                : AppColors.textOnPrimary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.primaryLight,
                  size: 14,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: done
                      ? AppColors.textOnPrimary
                      : AppColors.textOnPrimary.withValues(alpha: 0.65),
                  fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

// ──────────────────────────────── stop button ───────────────────────────────

class _StopButton extends StatefulWidget {
  const _StopButton({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onConfirmed();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() => _isHolding = true);
    _holdController.forward();
  }

  void _onHoldEnd() {
    setState(() => _isHolding = false);
    _holdController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SOS\'u kapat',
      hint: 'Basılı tutarak yaklaşık bir saniye bekleyin. Düdük durur ve SOS sonlanır.',
      onLongPress: widget.onConfirmed,
      excludeSemantics: true,
      child: GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: _onHoldEnd,
      child: AnimatedScale(
        scale: _isHolding ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Hold progress fill
                AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _holdController.value,
                      child: Container(
                        color: AppColors.critical.withValues(alpha: 0.85),
                      ),
                    );
                  },
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _holdController,
                        builder: (context, _) {
                          final color = Color.lerp(
                            const Color(0xFF1A0808),
                            AppColors.textOnPrimary,
                            _holdController.value,
                          )!;
                          return Icon(
                            Icons.stop_rounded,
                            color: color,
                            size: 28,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _holdController,
                        builder: (context, _) {
                          final color = Color.lerp(
                            const Color(0xFF1A0808),
                            AppColors.textOnPrimary,
                            _holdController.value,
                          )!;
                          return Text(
                            _isHolding
                                ? 'Bırak veya bekle...'
                                : 'BASILI TUT — KAPAT',
                            style: AppTypography.buttonLarge.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
