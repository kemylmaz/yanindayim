import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../shared/widgets/yaninda_text_field.dart';
import 'widgets/auth_mode_toggle.dart';

class VictimAuthScreen extends StatefulWidget {
  const VictimAuthScreen({super.key});

  @override
  State<VictimAuthScreen> createState() => _VictimAuthScreenState();
}

class _VictimAuthScreenState extends State<VictimAuthScreen> {
  AuthMode _mode = AuthMode.signup;

  // Signup
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  String? _bloodType;

  // Login
  final _loginPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _loginPhoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // TODO(hive): kullanici bilgisini lokal depolamaya yaz.
    context.go('/victim');
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
                        ? 'Yanında olmaya hazırız.'
                        : 'Tekrar hoş geldin.',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.primaryDeep,
                      height: 1.1,
                    ),
                  ).animate(key: ValueKey(_mode)).fadeIn(duration: 250.ms),
                  const SizedBox(height: 8),
                  Text(
                    _mode == AuthMode.signup
                        ? 'Mağdur modunda devam etmek için birkaç bilgi alalım.'
                        : 'Telefon numaranla devam et.',
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
                            phoneCtrl: _phoneCtrl,
                            emergencyCtrl: _emergencyCtrl,
                            bloodType: _bloodType,
                            onBloodTypeChanged: (v) =>
                                setState(() => _bloodType = v),
                          )
                        : _LoginForm(
                            key: const ValueKey('login'),
                            phoneCtrl: _loginPhoneCtrl,
                          ),
                  ),
                  const SizedBox(height: 28),
                  _PrimaryButton(
                    label: _mode == AuthMode.signup ? 'Hesap oluştur' : 'Giriş yap',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verileriniz sadece bu cihazda kalır.',
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
    required this.phoneCtrl,
    required this.emergencyCtrl,
    required this.bloodType,
    required this.onBloodTypeChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emergencyCtrl;
  final String? bloodType;
  final ValueChanged<String?> onBloodTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        YanindaTextField(
          label: 'Ad Soyad',
          hint: 'Kemal Yılmaz',
          controller: nameCtrl,
          icon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        YanindaTextField(
          label: 'Telefon',
          hint: '+90 555 123 45 67',
          controller: phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
          ],
        ),
        const SizedBox(height: 16),
        YanindaTextField(
          label: 'Acil iletişim',
          hint: 'Yakınının telefonu',
          controller: emergencyCtrl,
          icon: Icons.contact_phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
          ],
        ),
        const SizedBox(height: 16),
        YanindaDropdown<String>(
          label: 'Kan grubu (opsiyonel)',
          icon: Icons.bloodtype_rounded,
          hint: 'Seç',
          value: bloodType,
          onChanged: onBloodTypeChanged,
          items: const [
            DropdownMenuItem(value: '0+', child: Text('0 Rh+')),
            DropdownMenuItem(value: '0-', child: Text('0 Rh−')),
            DropdownMenuItem(value: 'A+', child: Text('A Rh+')),
            DropdownMenuItem(value: 'A-', child: Text('A Rh−')),
            DropdownMenuItem(value: 'B+', child: Text('B Rh+')),
            DropdownMenuItem(value: 'B-', child: Text('B Rh−')),
            DropdownMenuItem(value: 'AB+', child: Text('AB Rh+')),
            DropdownMenuItem(value: 'AB-', child: Text('AB Rh−')),
          ],
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({super.key, required this.phoneCtrl});

  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        YanindaTextField(
          label: 'Telefon',
          hint: '+90 555 123 45 67',
          controller: phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
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
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Mağdur modu',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryDeep,
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
