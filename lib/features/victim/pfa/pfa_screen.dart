import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'pfa_engine.dart';
import 'widgets/breathing_exercise.dart';

class PfaScreen extends StatefulWidget {
  const PfaScreen({super.key});

  @override
  State<PfaScreen> createState() => _PfaScreenState();
}

class _PfaScreenState extends State<PfaScreen> {
  PfaFlow? _flow;
  String? _currentNodeId;

  @override
  void initState() {
    super.initState();
    _loadFlow();
  }

  Future<void> _loadFlow() async {
    final flow = await PfaFlow.load();
    if (!mounted) return;
    setState(() {
      _flow = flow;
      _currentNodeId = flow.rootNodeId;
    });
  }

  void _goToNode(String id) {
    if (_flow == null) return;
    final node = _flow![id];
    if (node == null) return;
    if (node.type == PfaNodeType.redirect && node.route != null) {
      context.go(node.route!);
      return;
    }
    setState(() => _currentNodeId = id);
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/victim');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flow == null || _currentNodeId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final node = _flow![_currentNodeId!]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _TopBar(onClose: _exit),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(0, 0.04), end: Offset.zero),
                    ),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(node.id),
                  child: _buildNode(node),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(PfaNode node) {
    switch (node.type) {
      case PfaNodeType.choice:
        return _ChoiceView(
          node: node,
          onSelect: _goToNode,
        );
      case PfaNodeType.info:
        return _InfoView(
          node: node,
          onNext: () {
            if (node.next != null) _goToNode(node.next!);
          },
        );
      case PfaNodeType.widget:
        return _WidgetView(
          node: node,
          onNext: () {
            if (node.next != null) _goToNode(node.next!);
          },
        );
      case PfaNodeType.redirect:
        return const SizedBox.shrink();
    }
  }
}

// ──────────────────────────────── top bar ───────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa_rounded,
                  color: AppColors.primarySoft, size: 14),
              const SizedBox(width: 6),
              Text(
                'Psikolojik İlk Yardım',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.primaryDeep,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── choice view ───────────────────────────────

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({required this.node, required this.onSelect});

  final PfaNode node;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final options = node.options ?? const <PfaOption>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (node.title != null)
            Text(
              node.title!,
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.primaryDeep,
                height: 1.1,
              ),
            ).animate().fadeIn(duration: 350.ms),
          if (node.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              node.subtitle!,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
          ],
          const SizedBox(height: 24),
          ...List.generate(options.length, (i) {
            final option = options[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionTile(
                label: option.label,
                onTap: () => onSelect(option.next),
              )
                  .animate(delay: (150 + i * 80).ms)
                  .fadeIn(duration: 350.ms)
                  .moveX(begin: -12, end: 0, duration: 350.ms),
            );
          }),
        ],
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
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
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
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

// ──────────────────────────────── info view ─────────────────────────────────

class _InfoView extends StatelessWidget {
  const _InfoView({required this.node, required this.onNext});

  final PfaNode node;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (node.title != null)
                    Text(
                      node.title!,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryDeep,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                  if (node.body != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      node.body!,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                  ],
                ],
              ),
            ),
          ),
          _PrimaryButton(
            label: node.nextLabel ?? 'Devam',
            onTap: onNext,
          ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
        ],
      ),
    );
  }
}

// ──────────────────────────────── widget view ───────────────────────────────

class _WidgetView extends StatelessWidget {
  const _WidgetView({required this.node, required this.onNext});

  final PfaNode node;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (node.widget == 'BreathingExercise') {
      final params = node.params ?? const <String, dynamic>{};
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: BreathingExercise(
          inhaleSeconds: (params['inhale'] as int?) ?? 4,
          holdSeconds: (params['hold'] as int?) ?? 7,
          exhaleSeconds: (params['exhale'] as int?) ?? 8,
          cycles: (params['cycles'] as int?) ?? 5,
          guidanceText: params['guidanceText'] as String?,
          onCompleted: onNext,
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Widget "${node.widget}" tanımlanmamış.',
          style: AppTypography.bodyMedium,
        ),
      ),
    );
  }
}

// ──────────────────────────────── primary button ────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primarySoft, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textOnPrimary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
