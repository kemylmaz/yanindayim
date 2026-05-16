import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';

enum SosPhase { countdown, active, stopped }

enum SosMilestone {
  whistleStarted,
  beaconActivated,
  smsSent,
  emergencyCalled,
}

@immutable
class SosState {
  const SosState({
    this.phase = SosPhase.countdown,
    this.countdownRemaining = _kCountdownStart,
    this.activeElapsed = 0,
    this.milestones = const <SosMilestone>{},
  });

  final SosPhase phase;
  final int countdownRemaining; // 5, 4, 3, 2, 1, 0
  final int activeElapsed; // 0..(activeTotal)
  final Set<SosMilestone> milestones;

  static const int _kCountdownStart = 5;
  static const int activeTotal = 60; // saniye

  SosState copyWith({
    SosPhase? phase,
    int? countdownRemaining,
    int? activeElapsed,
    Set<SosMilestone>? milestones,
  }) {
    return SosState(
      phase: phase ?? this.phase,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
      activeElapsed: activeElapsed ?? this.activeElapsed,
      milestones: milestones ?? this.milestones,
    );
  }
}

class SosController extends StateNotifier<SosState> {
  SosController(this._audio) : super(const SosState()) {
    _tickEverySecond();
  }

  final AudioService _audio;
  Timer? _timer;

  void _tickEverySecond() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _onTick() async {
    switch (state.phase) {
      case SosPhase.countdown:
        await _handleCountdownTick();
      case SosPhase.active:
        await _handleActiveTick();
      case SosPhase.stopped:
        _timer?.cancel();
    }
  }

  Future<void> _handleCountdownTick() async {
    final next = state.countdownRemaining - 1;
    if (next <= 0) {
      // Geri sayım bitti — aktif faza geç, düdük başla.
      await _audio.playWhistle();
      state = state.copyWith(
        phase: SosPhase.active,
        countdownRemaining: 0,
        activeElapsed: 0,
        milestones: {SosMilestone.whistleStarted, SosMilestone.beaconActivated},
      );
    } else {
      state = state.copyWith(countdownRemaining: next);
    }
  }

  Future<void> _handleActiveTick() async {
    final next = state.activeElapsed + 1;
    var milestones = state.milestones;

    // 60 saniye dolduğunda SMS gönder + 112 ara (simüle).
    if (next == SosState.activeTotal) {
      milestones = {
        ...milestones,
        SosMilestone.smsSent,
        SosMilestone.emergencyCalled,
      };
      // TODO(production): url_launcher ile sms: ve tel:112 intent açılır.
    }

    state = state.copyWith(
      activeElapsed: next,
      milestones: milestones,
    );
  }

  /// Kullanıcı SOS'u iptal etti veya kapattı.
  Future<void> cancel() async {
    _timer?.cancel();
    await _audio.stopWhistle();
    state = state.copyWith(phase: SosPhase.stopped);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.stopWhistle();
    super.dispose();
  }
}

final sosControllerProvider =
    StateNotifierProvider.autoDispose<SosController, SosState>((ref) {
  return SosController(AudioService.instance);
});
