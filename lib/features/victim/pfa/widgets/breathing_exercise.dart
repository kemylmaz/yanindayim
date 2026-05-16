import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

enum _BreathPhase { inhale, hold, exhale }

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({
    super.key,
    this.inhaleSeconds = 4,
    this.holdSeconds = 7,
    this.exhaleSeconds = 8,
    this.cycles = 5,
    this.guidanceText,
    required this.onCompleted,
  });

  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int cycles;
  final String? guidanceText;
  final VoidCallback onCompleted;

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  _BreathPhase _phase = _BreathPhase.inhale;
  int _cycleIndex = 0;
  int _phaseSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this);
    _startPhase(_BreathPhase.inhale);
  }

  @override
  void dispose() {
    _circleController.dispose();
    super.dispose();
  }

  void _startPhase(_BreathPhase phase) async {
    final seconds = switch (phase) {
      _BreathPhase.inhale => widget.inhaleSeconds,
      _BreathPhase.hold => widget.holdSeconds,
      _BreathPhase.exhale => widget.exhaleSeconds,
    };

    setState(() {
      _phase = phase;
      _phaseSecondsLeft = seconds;
    });

    _circleController.duration = Duration(seconds: seconds);
    if (phase == _BreathPhase.inhale) {
      _circleController.forward(from: 0);
    } else if (phase == _BreathPhase.exhale) {
      _circleController.reverse(from: 1);
    } else {
      // Hold: maintain current value
    }

    for (var s = seconds; s > 0; s--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _phaseSecondsLeft = s - 1);
    }

    if (!mounted) return;

    switch (phase) {
      case _BreathPhase.inhale:
        _startPhase(_BreathPhase.hold);
      case _BreathPhase.hold:
        _startPhase(_BreathPhase.exhale);
      case _BreathPhase.exhale:
        if (_cycleIndex + 1 >= widget.cycles) {
          widget.onCompleted();
        } else {
          setState(() => _cycleIndex++);
          _startPhase(_BreathPhase.inhale);
        }
    }
  }

  String get _phaseLabel => switch (_phase) {
        _BreathPhase.inhale => 'Nefes al',
        _BreathPhase.hold => 'Tut',
        _BreathPhase.exhale => 'Yavaşça ver',
      };

  Color get _phaseColor => switch (_phase) {
        _BreathPhase.inhale => AppColors.primaryLight,
        _BreathPhase.hold => AppColors.primarySoft,
        _BreathPhase.exhale => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Tur ${_cycleIndex + 1} / ${widget.cycles}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _circleController,
            builder: (context, _) {
              final t = _circleController.value;
              // Inhale: 0.4 → 1.0, Hold: stays at 1.0 or current, Exhale: 1.0 → 0.4
              final scale = 0.4 + t * 0.6;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale * 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _phaseColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: scale * 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _phaseColor.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: scale * 0.65,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_phaseColor, AppColors.primaryDeep],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _phaseColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _phaseLabel,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_phaseSecondsLeft',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontSize: 64,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (widget.guidanceText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.guidanceText!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryDeep.withValues(alpha: 0.75),
              ),
            ),
          ),
      ],
    );
  }
}
