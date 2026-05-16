import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (_mode == AuthMode.signup) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showError('Lütfen adınızı ve soyadınızı girin.');
        return;
      }
      if (_phoneCtrl.text.trim().length != 10 || !_phoneCtrl.text.startsWith('5')) {
        _showError('Lütfen 5 ile başlayan 10 haneli geçerli bir telefon numarası girin.');
        return;
      }
    } else {
      if (_loginPhoneCtrl.text.trim().length != 10 || !_loginPhoneCtrl.text.startsWith('5')) {
        _showError('Lütfen 5 ile başlayan 10 haneli telefon numaranızı girin.');
        return;
      }
    }

    final phone = _mode == AuthMode.signup ? _phoneCtrl.text : _loginPhoneCtrl.text;
    _sendOtp(phone);
  }

  Future<void> _sendOtp(String phone) async {
    try {
      // "+90" is prepended because the form expects 10 digits starting with 5.
      await Supabase.instance.client.auth.signInWithOtp(phone: '+90$phone');
      
      if (!mounted) return;
      _showOtpVerification(phone);
    } catch (e) {
      if (!mounted) return;
      _showError('SMS gönderilemedi. Hata: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOtpVerification(String phone) {
    final otpCtrl = TextEditingController();
    
    // Simulate SMS notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 SMS Geldi: Yanında doğrulama kodunuz: 123456'),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.info,
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'SMS Doğrulama', 
          style: AppTypography.headlineMedium.copyWith(color: AppColors.primaryDeep),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$phone numarasına gönderilen 6 haneli kodu girin.', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '123456',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (otpCtrl.text.length == 6) {
                try {
                  final res = await Supabase.instance.client.auth.verifyOTP(
                    phone: '+90$phone',
                    token: otpCtrl.text,
                    type: OtpType.sms,
                  );
                  
                  if (res.user != null) {
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close dialog
                    // TODO(hive): kullanici bilgisini lokal depolamaya yaz.
                    context.go('/victim');
                  } else {
                    _showError('Doğrulama başarısız oldu.');
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  _showError('Hatalı kod veya geçersiz istek.');
                }
              } else {
                _showError('Lütfen 6 haneli kodu girin.');
              }
            },
            child: const Text('Doğrula', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          hint: 'Ad - Soyad',
          controller: nameCtrl,
          icon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        YanindaTextField(
          label: 'Telefon',
          hint: '5XX XXX XX XX',
          controller: phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 16),
        YanindaTextField(
          label: 'Acil iletişim (Opsiyonel)',
          hint: '5XX XXX XX XX',
          controller: emergencyCtrl,
          icon: Icons.contact_phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
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
          hint: '5XX XXX XX XX',
          controller: phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
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
