import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/checkin_contacts_service.dart';
import '../../core/services/health_card_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(healthCardProvider);
    final contacts = ref.watch(checkinContactsProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final fullName = card.fullName.isNotEmpty
        ? card.fullName
        : (user?.userMetadata?['full_name'] as String?)?.trim().isNotEmpty ==
                true
            ? user!.userMetadata!['full_name'] as String
            : (user?.email?.split('@').first ?? 'Misafir');
    final role = user?.userMetadata?['role'] as String? ?? 'victim';
    final roleLabel =
        role == 'rescuer' ? 'Destek birimi modu' : 'Depremzede modu';

    final bloodPart =
        (card.bloodType != null && card.bloodType!.isNotEmpty)
            ? ' · ${card.bloodType}'
            : '';
    final contactPart =
        contacts.isEmpty ? '' : ' · ${contacts.length} yakın';
    final profileSubtitle = '$roleLabel$bloodPart$contactPart';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(
                          onBack: () => context.canPop()
                              ? context.pop()
                              : context.go('/victim'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ayarlar',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.primaryDeep,
                            height: 1.1,
                            fontSize: 26,
                          ),
                        ).animate().fadeIn(duration: 350.ms),
                        const SizedBox(height: 14),
                        _ProfileCard(
                          name: fullName,
                          subtitle: profileSubtitle,
                          email: user?.email,
                        )
                            .animate(delay: 80.ms)
                            .fadeIn(duration: 380.ms)
                            .moveY(begin: 8, end: 0, duration: 380.ms),
                      ],
                    ),
                  ),
                ),

                // HESAP & VERİ
                _section('HESAP & VERİ'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SettingTile(
                        icon: Icons.health_and_safety_rounded,
                        title: 'Sağlık Kartım',
                        subtitle: card.isEmpty
                            ? 'Henüz oluşturulmadı — dokun, ekle'
                            : 'Kan grubu, alerji, ilaçlar girildi',
                        iconColor: AppColors.critical,
                        onTap: () => context.push('/victim/health'),
                      ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _SettingTile(
                        icon: Icons.contacts_rounded,
                        title: 'Güvendeyim kişilerim',
                        subtitle: contacts.isEmpty
                            ? 'Henüz kişi eklenmedi'
                            : '${contacts.length} kişi kayıtlı',
                        onTap: () => context.push('/victim/checkin'),
                      ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _SettingTile(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Modu değiştir',
                        subtitle: 'Depremzede ↔ Destek birimi',
                        iconColor: AppColors.teal,
                        onTap: () => context.go('/onboarding'),
                      ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                    ]),
                  ),
                ),

                // GÜVENLİK ÖZELLİKLERİ
                _section('GÜVENLİK ÖZELLİKLERİ'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _InfoTile(
                        icon: Icons.bluetooth_searching_rounded,
                        title: 'BLE Beacon yayını',
                        subtitle:
                            'SOS aktif olunca anonim ID ile yakındaki kurtarıcılara sinyal',
                        iconColor: AppColors.primary,
                      ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.volume_up_rounded,
                        title: 'Acil durum düdüğü',
                        subtitle:
                            'Fox 40 / AFAD standardı · 2.7-3.3 kHz dual-tone',
                        iconColor: AppColors.critical,
                      ).animate(delay: 360.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.lock_open_rounded,
                        title: 'Kilit ekranı bypass',
                        subtitle:
                            'SOS aktifken telefon uyandığında kilit açmadan sağlık kartı görünür',
                        iconColor: AppColors.amber,
                      ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.accessibility_new_rounded,
                        title: 'Erişilebilirlik',
                        subtitle:
                            'Görme engelliler için sesli komut · işitme engelliler için titreşim',
                        iconColor: AppColors.teal,
                      ).animate(delay: 440.ms).fadeIn(duration: 300.ms),
                    ]),
                  ),
                ),

                // ÇEVRİMDIŞI KAPSAMI
                _section('ÇEVRİMDIŞI KAPSAM'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _InfoTile(
                        icon: Icons.psychology_rounded,
                        title: 'Yapay Zeka Asistanı',
                        subtitle:
                            '14 acil durum senaryosu + 32 bilgi chunk\'ı · Türkçe yanıt',
                        iconColor: AppColors.teal,
                      ).animate(delay: 510.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.map_rounded,
                        title: 'Çevrimdışı harita',
                        subtitle:
                            'Balıkesir bölgesi · 20 AFAD toplanma alanı · tile cache',
                        iconColor: AppColors.amber,
                      ).animate(delay: 550.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.book_rounded,
                        title: 'Yerel bilgi bankası',
                        subtitle:
                            'Deprem öncesi/sırası/sonrası + PFA + ilk yardım rehberleri',
                        iconColor: AppColors.primary,
                      ).animate(delay: 590.ms).fadeIn(duration: 300.ms),
                    ]),
                  ),
                ),

                // GİZLİLİK & HAKKINDA
                _section('GİZLİLİK & HAKKINDA'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _InfoTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Gizlilik',
                        subtitle:
                            'Veriler cihazında kalır · Beacon ID anonimdir · KVKK uyumlu',
                        iconColor: AppColors.primary,
                      ).animate(delay: 660.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _SettingTile(
                        icon: Icons.code_rounded,
                        title: 'Açık kaynak',
                        subtitle: 'github.com/kemylmaz/AppJam_DepremApp',
                        iconColor: AppColors.primary,
                        onTap: () => _openUrl(
                          context,
                          'https://github.com/kemylmaz/AppJam_DepremApp',
                        ),
                      ).animate(delay: 700.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Sürüm',
                        subtitle: 'v0.1.0 · AppJam 2026 hackathon',
                        iconColor: AppColors.textSecondary,
                      ).animate(delay: 740.ms).fadeIn(duration: 300.ms),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _LogoutButton(
                      onTap: () => _confirmLogout(context, ref),
                    ).animate(delay: 820.ms).fadeIn(duration: 350.ms),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      sliver: SliverToBoxAdapter(child: _SectionLabel(label: label)),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı açılamadı: $url')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Çıkış yap?',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.primaryDeep,
          ),
        ),
        content: Text(
          'Oturumun kapatılır, bir sonraki açılışta giriş ekranı gelir. Kişiler ve sağlık kartın cihazda kalır.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'İptal',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Çıkış yap',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.critical,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (context.mounted) context.go('/onboarding');
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
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.email,
  });

  final String name;
  final String subtitle;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
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
              color: AppColors.textOnPrimary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 19,
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.textOnPrimary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

/// Tıklanabilir ayar satırı (sağda chevron).
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
        child: _tileShell(
          color: color,
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Bilgi satırı — tıklanmaz, sadece özellik göstergesi (chevron yok).
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return _tileShell(
      color: iconColor,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Aktif',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

Widget _tileShell({
  required Color color,
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget trailing,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
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
          border:
              Border.all(color: AppColors.critical.withValues(alpha: 0.4)),
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
