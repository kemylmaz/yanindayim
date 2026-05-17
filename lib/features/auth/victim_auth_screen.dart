import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // İlk açılışta varsayılan: giriş yap (zaten kayıtlı kullanıcı için).
  AuthMode _mode = AuthMode.login;
  bool _busy = false;
  bool _rememberMe = true;

  // Signup
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  String? _bloodType;
  int _passwordStrength = 0; // 0..4

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  static const _kRememberedEmailKey = 'victim_remembered_email';

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
    _passwordCtrl.addListener(_recomputeStrength);
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kRememberedEmailKey);
    if (email != null && email.isNotEmpty && mounted) {
      setState(() => _loginEmailCtrl.text = email);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emergencyCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  void _recomputeStrength() {
    setState(() => _passwordStrength = _computeStrength(_passwordCtrl.text));
  }

  /// Şifre gücü 0-4 arası. 0: çok zayıf, 4: çok güçlü.
  int _computeStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    var score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    final hasLetter = pwd.contains(RegExp(r'[A-Za-zçğıöşüÇĞİÖŞÜ]'));
    final hasDigit = pwd.contains(RegExp(r'[0-9]'));
    final hasSpecial = pwd.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:,.<>?/|]'));
    if (hasLetter && (hasDigit || hasSpecial)) score++;
    if (hasLetter && hasDigit && hasSpecial) score++;
    return score.clamp(0, 4);
  }

  /// Şifre kural ihlali varsa hata mesajı, yoksa null döner.
  String? _validatePasswordRules(String pwd) {
    if (pwd.length < 8) return 'Şifre en az 8 karakter olmalı.';
    // Ardışık 4+ rakam yasak (1234, 12345 gibi).
    if (RegExp(r'\d{4,}').hasMatch(pwd)) {
      return 'Şifre ardışık 4 veya daha fazla rakam içeremez.';
    }
    // Yaygın basit şifreler yasak.
    const weak = {
      '12345678', '123456789', '1234567890',
      'password', 'parola', 'qwerty', 'qwertyui',
      '11111111', '00000000', 'abcdefgh',
    };
    if (weak.contains(pwd.toLowerCase())) {
      return 'Bu şifre çok yaygın. Daha karmaşık bir şifre seç.';
    }
    // Sadece harf veya sadece rakam olmasın.
    if (RegExp(r'^[A-Za-zçğıöşüÇĞİÖŞÜ]+$').hasMatch(pwd)) {
      return 'Şifre rakam veya özel karakter içermeli.';
    }
    if (RegExp(r'^[0-9]+$').hasMatch(pwd)) {
      return 'Sadece rakamdan oluşan şifre kullanılamaz.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;

    if (_mode == AuthMode.signup) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showError('Lütfen adınızı ve soyadınızı girin.');
        return;
      }
      if (!_isValidEmail(_emailCtrl.text)) {
        _showError('Geçerli bir e-posta adresi girin.');
        return;
      }
      final pwdError = _validatePasswordRules(_passwordCtrl.text);
      if (pwdError != null) {
        _showError(pwdError);
        return;
      }
    } else {
      if (!_isValidEmail(_loginEmailCtrl.text)) {
        _showError('Geçerli bir e-posta adresi girin.');
        return;
      }
      if (_loginPasswordCtrl.text.isEmpty) {
        _showError('Şifrenizi girin.');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      if (_mode == AuthMode.signup) {
        final res = await Supabase.instance.client.auth
            .signUp(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              data: {
                'full_name': _nameCtrl.text.trim(),
                'role': 'victim',
                'blood_type': _bloodType,
                'emergency_contact': _emergencyCtrl.text.trim(),
              },
            )
            .timeout(const Duration(seconds: 20));
        if (!mounted) return;
        if (res.user != null) {
          await _persistRememberedEmail(_emailCtrl.text.trim());
          _showInfo(
            res.session != null
                ? 'Hesap oluşturuldu, giriş yapıldı.'
                : 'Doğrulama e-postası gönderildi. Posta kutunuzu kontrol edin.',
          );
          if (mounted) context.go('/victim');
        } else {
          _showError('Kayıt başarısız.');
        }
      } else {
        final res = await Supabase.instance.client.auth
            .signInWithPassword(
              email: _loginEmailCtrl.text.trim(),
              password: _loginPasswordCtrl.text,
            )
            .timeout(const Duration(seconds: 20));
        if (!mounted) return;
        if (res.user != null) {
          await _persistRememberedEmail(
            _rememberMe ? _loginEmailCtrl.text.trim() : null,
          );
          if (mounted) context.go('/victim');
        } else {
          _showError('Giriş başarısız.');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
          'Bağlantı sorunu — internetinizi kontrol edip tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistRememberedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_kRememberedEmailKey);
    } else {
      await prefs.setString(_kRememberedEmailKey, email);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _loginEmailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      _showError(
        'Önce e-posta alanına geçerli bir adres girin, sonra "Şifremi unuttum"a basın.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _showInfo(
          'Şifre sıfırlama bağlantısı $email adresine gönderildi.');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Bağlantı sorunu — tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
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
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onBack: () => context.go('/onboarding')),
                    const SizedBox(height: 14),
                    Text(
                      _mode == AuthMode.signup
                          ? 'Yanındayım\'a hoş geldin.'
                          : 'Tekrar hoş geldin.',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryDeep,
                        height: 1.1,
                      ),
                    ).animate(key: ValueKey(_mode)).fadeIn(duration: 250.ms),
                    const SizedBox(height: 6),
                    Text(
                      _mode == AuthMode.signup
                          ? 'Mağdur modunda devam etmek için birkaç bilgi alalım.'
                          : 'E-posta ve şifrenle devam et.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                        .animate(key: ValueKey('subtitle-$_mode'))
                        .fadeIn(duration: 250.ms),
                    const SizedBox(height: 14),
                    AuthModeToggle(
                      mode: _mode,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _mode == AuthMode.signup
                          ? _SignupForm(
                              key: const ValueKey('signup'),
                              nameCtrl: _nameCtrl,
                              emailCtrl: _emailCtrl,
                              passwordCtrl: _passwordCtrl,
                              emergencyCtrl: _emergencyCtrl,
                              bloodType: _bloodType,
                              onBloodTypeChanged: (v) =>
                                  setState(() => _bloodType = v),
                              strength: _passwordStrength,
                            )
                          : _LoginForm(
                              key: const ValueKey('login'),
                              emailCtrl: _loginEmailCtrl,
                              passwordCtrl: _loginPasswordCtrl,
                              rememberMe: _rememberMe,
                              onRememberChanged: (v) =>
                                  setState(() => _rememberMe = v),
                              onForgotPassword: _sendPasswordReset,
                            ),
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: _busy
                          ? 'Lütfen bekleyin…'
                          : (_mode == AuthMode.signup
                              ? 'Hesap oluştur'
                              : 'Giriş yap'),
                      onTap: _submit,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Doğrulama bağlantısı e-posta ile gelir.',
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
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.emergencyCtrl,
    required this.bloodType,
    required this.onBloodTypeChanged,
    required this.strength,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController emergencyCtrl;
  final String? bloodType;
  final ValueChanged<String?> onBloodTypeChanged;
  final int strength;

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
        const SizedBox(height: 10),
        YanindaTextField(
          label: 'E-posta',
          hint: 'isim@ornek.com',
          controller: emailCtrl,
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        YanindaTextField(
          label: 'Şifre',
          hint: 'En az 8 karakter, harf + rakam/özel',
          controller: passwordCtrl,
          icon: Icons.lock_rounded,
          obscureText: true,
        ),
        const SizedBox(height: 8),
        _PasswordStrengthBar(strength: strength),
        const SizedBox(height: 10),
        YanindaTextField(
          label: 'Acil iletişim (Opsiyonel)',
          hint: '5XX XXX XX XX',
          controller: emergencyCtrl,
          icon: Icons.contact_phone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
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

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final int strength; // 0..4

  static const _labels = ['Çok zayıf', 'Zayıf', 'Orta', 'İyi', 'Güçlü'];

  Color _color() {
    switch (strength) {
      case 0:
        return AppColors.border;
      case 1:
        return AppColors.critical;
      case 2:
        return AppColors.amber;
      case 3:
        return AppColors.teal;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final pct = (strength / 4).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 6, color: AppColors.border),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                widthFactor: pct,
                child: Container(height: 6, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strength == 0 ? 'Şifre gücü' : _labels[strength],
          style: AppTypography.labelSmall.copyWith(
            color: strength == 0 ? AppColors.textSecondary : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        YanindaTextField(
          label: 'E-posta',
          hint: 'isim@ornek.com',
          controller: emailCtrl,
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        YanindaTextField(
          label: 'Şifre',
          hint: 'Şifreniz',
          controller: passwordCtrl,
          icon: Icons.lock_rounded,
          obscureText: true,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Parolamı hatırla
            InkWell(
              onTap: () => onRememberChanged(!rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (v) => onRememberChanged(v ?? false),
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parolamı hatırla',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Şifremi unuttum
            TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Şifremi unuttum',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
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
