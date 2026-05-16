import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onBack: () => context.go('/victim')),
                    const SizedBox(height: 24),
                    Text(
                      'Ayarlar',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryDeep,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 24),
                    _ProfileCard()
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 8, end: 0, duration: 400.ms),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel(label: 'HESAP'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SettingTile(
                    icon: Icons.person_rounded,
                    title: 'Kişisel bilgilerim',
                    subtitle: 'Ad, telefon, kan grubu',
                    onTap: () {},
                  ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.contact_phone_rounded,
                    title: 'Acil iletişim listesi',
                    subtitle: '3 kişi kayıtlı',
                    onTap: () {},
                  ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.medical_information_rounded,
                    title: 'Sağlık notları',
                    subtitle: 'Alerjiler, kronik hastalıklar',
                    onTap: () {},
                  ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Modu değiştir',
                    subtitle: 'Mağdur ↔ Destek ve Kurtarma',
                    onTap: () => context.go('/onboarding'),
                  ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel(label: 'UYGULAMA'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SettingTile(
                    icon: Icons.bluetooth_searching_rounded,
                    title: 'Beacon ayarları',
                    subtitle: 'Yayın aralığı, otomatik tetik',
                    onTap: () {},
                  ).animate(delay: 450.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.psychology_rounded,
                    title: 'Lokal AI modeli',
                    subtitle: 'Gemma 2B · 1,2 GB · İndirildi',
                    iconColor: AppColors.teal,
                    onTap: () {},
                  ).animate(delay: 500.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.map_rounded,
                    title: 'Offline harita',
                    subtitle: 'Türkiye paketi · 245 MB',
                    iconColor: AppColors.amber,
                    onTap: () {},
                  ).animate(delay: 550.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Düdük sesi',
                    subtitle: '3 kHz · Maksimum ses',
                    onTap: () {},
                  ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.language_rounded,
                    title: 'Dil',
                    subtitle: 'Türkçe',
                    onTap: () {},
                  ).animate(delay: 650.ms).fadeIn(duration: 300.ms),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel(label: 'YANINDA HAKKINDA'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SettingTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Gizlilik',
                    subtitle: 'Veriler cihazdan ayrılmaz',
                    onTap: () {},
                  ).animate(delay: 750.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.code_rounded,
                    title: 'Açık kaynak',
                    subtitle: 'github.com/kemylmaz/AppJam_DepremApp',
                    onTap: () {},
                  ).animate(delay: 800.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Sürüm',
                    subtitle: 'v0.1.0 · AppJam 2026',
                    onTap: () {},
                  ).animate(delay: 850.ms).fadeIn(duration: 300.ms),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _LogoutButton(
                  onTap: () => context.go('/onboarding'),
                ).animate(delay: 950.ms).fadeIn(duration: 350.ms),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────── widgets ───────────────────────────────────

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
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.textOnPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kemal Yılmaz',
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 20,
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.textOnPrimary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Depremzede modu · A+ · 1 yakın',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SettingTile extends StatefulWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppColors.primary;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
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
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.critical.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.critical,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Çıkış yap',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.critical,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
