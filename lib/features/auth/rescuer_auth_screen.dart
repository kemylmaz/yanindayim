import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../shared/widgets/yaninda_text_field.dart';
import 'widgets/auth_mode_toggle.dart';

class RescuerAuthScreen extends StatefulWidget {
  const RescuerAuthScreen({super.key});

  @override
  State<RescuerAuthScreen> createState() => _RescuerAuthScreenState();
}

class _RescuerAuthScreenState extends State<RescuerAuthScreen> {
  AuthMode _mode = AuthMode.signup;

  // Signup
  final _nameCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  String? _organization;
  String? _specialization;

  // Login
  final _loginCertCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _certCtrl.dispose();
    _loginCertCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // TODO(hive): kayitli kurtarici bilgisini lokal depolamaya yaz.
    context.go('/rescuer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(onBack: () => context.go('/onboarding')),
                  const SizedBox(height: 24),
                  Text(
                    _mode == AuthMode.signup
                        ? 'Kurtarmaya geldin.'
                        : 'Tekrar hoş geldin.',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.rescuer,
                      height: 1.1,
                    ),
                  ).animate(key: ValueKey(_mode)).fadeIn(duration: 250.ms),
                  const SizedBox(height: 8),
                  Text(
                    _mode == AuthMode.signup
                        ? 'Sertifika bilgilerinle başlayalım. Mağdurları görmen için doğrulama gerekli.'
                        : 'Sertifika numaranla devam et.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate(key: ValueKey('subtitle-$_mode'))
                      .fadeIn(duration: 250.ms),
                  const SizedBox(height: 24),
                  AuthModeToggle(
                    mode: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _mode == AuthMode.signup
                        ? _SignupForm(
                            key: const ValueKey('signup'),
                            nameCtrl: _nameCtrl,
                            certCtrl: _certCtrl,
                            organization: _organization,
                            onOrganizationChanged: (v) =>
                                setState(() => _organization = v),
                            specialization: _specialization,
                            onSpecializationChanged: (v) =>
                                setState(() => _specialization = v),
                          )
                        : _LoginForm(
                            key: const ValueKey('login'),
                            certCtrl: _loginCertCtrl,
                          ),
                  ),
                  const SizedBox(height: 28),
                  _PrimaryButton(
                    label: _mode == AuthMode.signup
                        ? 'Sertifikamı doğrula'
                        : 'Giriş yap',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sertifika gerçekliği sahada doğrulanır.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
    );
  }
}

// ──────────────────────────────── forms ─────────────────────────────────────

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    super.key,
    required this.nameCtrl,
    required this.certCtrl,
    required this.organization,
    required this.onOrganizationChanged,
    required this.specialization,
    required this.onSpecializationChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController certCtrl;
  final String? organization;
  final ValueChanged<String?> onOrganizationChanged;
  final String? specialization;
  final ValueChanged<String?> onSpecializationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        YanindaTextField(
          label: 'Ad Soyad',
          hint: 'Ahmet Demir',
          controller: nameCtrl,
          icon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        YanindaDropdown<String>(
          label: 'Kuruluş',
          icon: Icons.business_rounded,
          hint: 'Kuruluş seç',
          value: organization,
          onChanged: onOrganizationChanged,
          items: const [
            DropdownMenuItem(value: 'AKUT', child: Text('AKUT')),
            DropdownMenuItem(value: 'AFAD', child: Text('AFAD')),
            DropdownMenuItem(value: 'UMKE', child: Text('UMKE')),
            DropdownMenuItem(value: 'Kızılay', child: Text('Kızılay')),
            DropdownMenuItem(value: 'AHBAP', child: Text('AHBAP')),
            DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
          ],
        ),
        const SizedBox(height: 16),
        YanindaTextField(
          label: 'Sertifika numarası',
          hint: 'AKUT-2024-12345',
          controller: certCtrl,
          icon: Icons.badge_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          ],
        ),
        const SizedBox(height: 16),
        YanindaDropdown<String>(
          label: 'Uzmanlık alanı',
          icon: Icons.medical_services_rounded,
          hint: 'Uzmanlık seç',
          value: specialization,
          onChanged: onSpecializationChanged,
          items: const [
            DropdownMenuItem(
              value: 'arama-kurtarma',
              child: Text('Arama-Kurtarma'),
            ),
            DropdownMenuItem(value: 'saglik', child: Text('Sağlık / İlk Yardım')),
            DropdownMenuItem(value: 'lojistik', child: Text('Lojistik')),
            DropdownMenuItem(
              value: 'koordinasyon',
              child: Text('Koordinasyon'),
            ),
            DropdownMenuItem(value: 'psikoloji', child: Text('Psikolojik Destek')),
          ],
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({super.key, required this.certCtrl});

  final TextEditingController certCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        YanindaTextField(
          label: 'Sertifika numarası',
          hint: 'AKUT-2024-12345',
          controller: certCtrl,
          icon: Icons.badge_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────── shared bits ───────────────────────────────

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
            color: AppColors.rescuer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_services_rounded,
                color: AppColors.rescuer,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Kurtarıcı modu',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.rescuer,
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
              colors: [AppColors.rescuerLight, AppColors.rescuer],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.rescuer.withValues(alpha: 0.35),
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
