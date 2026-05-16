import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/emergency_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool _sending = false;
  bool _sent = false;

  static const _contacts = <_Contact>[
    _Contact(name: 'Anne', phone: '+90 555 111 22 33'),
    _Contact(name: 'Baba', phone: '+90 555 222 33 44'),
    _Contact(name: 'Kardeş', phone: '+90 555 333 44 55'),
  ];

  Future<void> _send() async {
    setState(() => _sending = true);
    final body =
        'Güvendeyim. Endişelenme — Yanında uygulamasından otomatik bildirim. '
        'Konum: https://maps.google.com/?q=41.0117,28.9810';
    final phones = _contacts.map((c) => c.phone.replaceAll(' ', '')).toList();
    await EmergencyService.instance.sendEmergencySms(
      recipients: phones,
      body: body,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(onBack: () => context.go('/victim')),
              const SizedBox(height: 24),
              Text(
                _sent ? 'Bildirim gönderildi.' : 'Güvende olduğunu bildir.',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primaryDeep,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'Aileniz bilgilendi. Şimdi nefes alma vakti.'
                    : 'Konumun ve "güvendeyim" mesajın aşağıdaki kişilere SMS olarak gidecek.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = _contacts[i];
                    return _ContactCard(
                      contact: c,
                      delivered: _sent,
                    )
                        .animate(delay: (200 + i * 80).ms)
                        .fadeIn(duration: 400.ms)
                        .moveX(begin: -12, end: 0, duration: 400.ms);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_sent)
                _SuccessButton(onTap: () => context.go('/victim'))
              else
                _PrimaryButton(
                  loading: _sending,
                  label: 'SMS\'leri gönder',
                  icon: Icons.send_rounded,
                  onTap: _send,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contact {
  const _Contact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.delivered});

  final _Contact contact;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  contact.phone,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: delivered
                  ? AppColors.primarySoft.withValues(alpha: 0.15)
                  : AppColors.background.withValues(alpha: 0.0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delivered
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: delivered
                      ? AppColors.primarySoft
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  delivered ? 'Gönderildi' : 'Bekliyor',
                  style: AppTypography.labelSmall.copyWith(
                    color: delivered
                        ? AppColors.primarySoft
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
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
          'Güvendeyim',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.loading,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

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
        onTapDown: widget.loading
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp:
            widget.loading ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            widget.loading ? null : () => setState(() => _pressed = false),
        onTap: widget.loading ? null : widget.onTap,
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
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: AppColors.textOnPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: AppTypography.buttonLarge.copyWith(
                          color: AppColors.textOnPrimary,
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

class _SuccessButton extends StatelessWidget {
  const _SuccessButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ana ekrana dön',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
