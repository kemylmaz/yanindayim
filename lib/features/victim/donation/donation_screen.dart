import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  static const _ngos = <_Ngo>[
    _Ngo(
      name: 'AKUT',
      description: 'Arama Kurtarma Derneği',
      url: 'https://akut.org.tr/bagis',
      initials: 'AK',
      color: Color(0xFFD32F2F),
    ),
    _Ngo(
      name: 'Kızılay',
      description: 'Türk Kızılay',
      url: 'https://www.kizilay.org.tr/bagis',
      initials: 'KZ',
      color: Color(0xFFC62828),
    ),
    _Ngo(
      name: 'AHBAP',
      description: 'AHBAP Platformu',
      url: 'https://ahbap.org/bagisci-ol',
      initials: 'AH',
      color: Color(0xFFE65100),
    ),
    _Ngo(
      name: 'İhtiyaç Haritası',
      description: 'Doğrudan ihtiyaç eşleştirme',
      url: 'https://www.ihtiyacharitasi.org',
      initials: 'İH',
      color: Color(0xFFC2185B),
    ),
    _Ngo(
      name: 'AFAD',
      description: 'Resmi afet koordinasyonu',
      url: 'https://www.afad.gov.tr',
      initials: 'AF',
      color: Color(0xFF1565C0),
    ),
    _Ngo(
      name: 'TEMA Vakfı',
      description: 'Çevre + afet sonrası rehabilitasyon',
      url: 'https://www.tema.org.tr/web_14966/bagis_yap.aspx',
      initials: 'TE',
      color: Color(0xFF2E7D32),
    ),
  ];

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı açılamadı: $url')),
      );
    }
  }

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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.amberSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: AppColors.amber,
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
                                  'Birlikte güçlüyüz.',
                                  style: AppTypography.headlineMedium.copyWith(
                                    fontSize: 20,
                                    height: 1.2,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bağışların doğrudan kuruluşun kendi sayfasına gider — biz aracı değiliz.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).moveY(
                          begin: 8,
                          end: 0,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 2,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'KURULUŞLAR',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ngo = _ngos[index];
                    return _NgoCard(
                      ngo: ngo,
                      onTap: () => _openUrl(context, ngo.url),
                    )
                        .animate(delay: (200 + index * 80).ms)
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 12, end: 0, duration: 400.ms);
                  },
                  childCount: _ngos.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Yanında bağışları işlemez — her bağış kurum sitesine yönlendirilir.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ngo {
  const _Ngo({
    required this.name,
    required this.description,
    required this.url,
    required this.initials,
    required this.color,
  });

  final String name;
  final String description;
  final String url;
  final String initials;
  final Color color;
}

class _NgoCard extends StatefulWidget {
  const _NgoCard({required this.ngo, required this.onTap});

  final _Ngo ngo;
  final VoidCallback onTap;

  @override
  State<_NgoCard> createState() => _NgoCardState();
}

class _NgoCardState extends State<_NgoCard> {
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.ngo.color.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.ngo.color.withValues(alpha: 0.9),
                      widget.ngo.color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.ngo.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.ngo.initials,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.ngo.name,
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 17,
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.ngo.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Bağış yap',
                        style: AppTypography.labelLarge.copyWith(
                          color: widget.ngo.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.ngo.color,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
        Text(
          'Bağış',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
