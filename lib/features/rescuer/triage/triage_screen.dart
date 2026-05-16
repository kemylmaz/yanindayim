import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// START / JumpSTART triaj kartı.
/// Sahada hızlı referans — kart-bazlı, sade, çabuk okunur.
class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  static const _categories = <_TriageCategory>[
    _TriageCategory(
      label: 'Siyah',
      sublabel: 'Ex',
      color: Color(0xFF2A2A2A),
      criteria: 'Solunum açma sonrası hâlâ solunum yoksa.',
    ),
    _TriageCategory(
      label: 'Kırmızı',
      sublabel: 'Acil',
      color: Color(0xFFC0392B),
      criteria:
          'Solunum >30/dk veya <10/dk, kapiller dolum >2 sn, komut anlamıyor.',
    ),
    _TriageCategory(
      label: 'Sarı',
      sublabel: 'Geciktirilmiş',
      color: Color(0xFFE5B928),
      criteria:
          'Yaralı ama vital bulgular stabil. Yürüyemez ama bilinçli, normal solunum.',
    ),
    _TriageCategory(
      label: 'Yeşil',
      sublabel: 'Hafif',
      color: Color(0xFF3FBE91),
      criteria: 'Yürüyebilir, kendi başına hareket eder.',
    ),
  ];

  static const _startSteps = <_TriageStep>[
    _TriageStep(
      number: 1,
      title: 'Yürüyebilir mi?',
      action: 'Evet → YEŞİL (hafif yaralı, toplanma alanına yönlendir).',
      details:
          'Yürüyebilen tüm yaralılar yeşil grupta — sahada bekleyecek, acil müdahale gerekmiyor.',
    ),
    _TriageStep(
      number: 2,
      title: 'Solunum var mı?',
      action: 'Yoksa hava yolunu aç. Hâlâ yoksa → SİYAH.',
      details:
          'Baş geri-çene yukarı manevra ile dili kaldır. Solunum başlarsa → KIRMIZI.',
    ),
    _TriageStep(
      number: 3,
      title: 'Solunum hızı?',
      action: '>30/dk veya <10/dk → KIRMIZI.',
      details: 'Çok hızlı veya çok yavaş solunum = hayati tehlike.',
    ),
    _TriageStep(
      number: 4,
      title: 'Kapiller dolum?',
      action: '>2 saniye → KIRMIZI. Yoksa SARI.',
      details:
          'Tırnağa bas, bırak. Yeniden pembe rengin gelmesi 2 saniyeden uzunsa şok belirtisi.',
    ),
    _TriageStep(
      number: 5,
      title: 'Komut anlıyor mu?',
      action: 'Hayır → KIRMIZI. Evet ve diğer kriterler iyiyse → SARI.',
      details:
          '"Elimi sık" gibi basit komutu yerine getirebiliyor mu? Yapamıyorsa nörolojik tehlike.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _TopBar(onBack: () => context.go('/rescuer')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Triaj Kartı',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryDeep,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 6),
                    Text(
                      'START / JumpSTART hızlı referans. Saha şartlarında öncelik sırasını belirler.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(width: 28, height: 2, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'KATEGORİLER',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _CategoryCard(category: _categories[i])
                      .animate(delay: (150 + i * 80).ms)
                      .fadeIn(duration: 350.ms)
                      .moveY(begin: 8, end: 0, duration: 350.ms),
                  childCount: _categories.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(width: 28, height: 2, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'AKIŞ ŞEMASI',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final s = _startSteps[i];
                    final isLast = i == _startSteps.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 24 : 10),
                      child: _StepCard(step: s)
                          .animate(delay: (450 + i * 80).ms)
                          .fadeIn(duration: 350.ms)
                          .moveX(begin: -10, end: 0, duration: 350.ms),
                    );
                  },
                  childCount: _startSteps.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriageCategory {
  const _TriageCategory({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.criteria,
  });

  final String label;
  final String sublabel;
  final Color color;
  final String criteria;
}

class _TriageStep {
  const _TriageStep({
    required this.number,
    required this.title,
    required this.action,
    required this.details,
  });

  final int number;
  final String title;
  final String action;
  final String details;
}

// ──────────────────────────────── widgets ───────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final _TriageCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: category.color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.label.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.sublabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              category.criteria,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({required this.step});

  final _TriageStep step;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppColors.primary
                : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.step.number}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.step.title,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.step.action,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: _expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12, left: 44),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.step.details,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryDeep,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primaryDeep,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.critical.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_information_rounded,
                color: AppColors.critical,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Saha protokolü',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.critical,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
