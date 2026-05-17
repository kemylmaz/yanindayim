import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // Tutarlılık için: depremzede ekranı gibi default "Giriş yap".
  AuthMode _mode = AuthMode.login;
  bool _busy = false;
  bool _rememberMe = true;

  // Signup
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _organization;
  String? _specialization;
  PlatformFile? _certificatePdf;
  int _passwordStrength = 0;

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  static const _kRememberedEmailKey = 'rescuer_remembered_email';

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
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  void _recomputeStrength() {
    setState(() => _passwordStrength = _computeStrength(_passwordCtrl.text));
  }

  int _computeStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    var score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    final hasLetter = pwd.contains(RegExp(r'[A-Za-zçğıöşüÇĞİÖŞÜ]'));
    final hasDigit = pwd.contains(RegExp(r'[0-9]'));
    final hasSpecial =
        pwd.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:,.<>?/|]'));
    if (hasLetter && (hasDigit || hasSpecial)) score++;
    if (hasLetter && hasDigit && hasSpecial) score++;
    return score.clamp(0, 4);
  }

  String? _validatePasswordRules(String pwd) {
    if (pwd.length < 8) return 'Şifre en az 8 karakter olmalı.';
    if (RegExp(r'\d{4,}').hasMatch(pwd)) {
      return 'Şifre ardışık 4 veya daha fazla rakam içeremez.';
    }
    const weak = {
      '12345678', '123456789', '1234567890',
      'password', 'parola', 'qwerty', 'qwertyui',
      '11111111', '00000000', 'abcdefgh',
    };
    if (weak.contains(pwd.toLowerCase())) {
      return 'Bu şifre çok yaygın. Daha karmaşık bir şifre seç.';
    }
    if (RegExp(r'^[A-Za-zçğıöşüÇĞİÖŞÜ]+$').hasMatch(pwd)) {
      return 'Şifre rakam veya özel karakter içermeli.';
    }
    if (RegExp(r'^[0-9]+$').hasMatch(pwd)) {
      return 'Sadece rakamdan oluşan şifre kullanılamaz.';
    }
    return null;
  }

  Future<void> _pickCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _certificatePdf = result.files.first);
      _showInfo('Belge yüklendi: ${_certificatePdf!.name}');
    } catch (e) {
      _showError('Belge seçilemedi: $e');
    }
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
      if (_organization == null) {
        _showError('Kuruluş seçin.');
        return;
      }
      if (_certificatePdf == null) {
        _showError(
          'e-Devlet\'ten aldığınız QR kodlu PDF belgeyi yüklemeniz gerekiyor.',
        );
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
                'role': 'rescuer',
                'organization': _organization,
                'specialization': _specialization,
                'certificate_filename': _certificatePdf?.name,
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
          if (mounted) context.go('/rescuer');
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
          if (mounted) context.go('/rescuer');
        } else {
          _showError('Giriş başarısız.');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
        'Bağlantı sorunu — internetinizi kontrol edip tekrar deneyin.',
      );
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
      _showInfo('Şifre sıfırlama bağlantısı $email adresine gönderildi.');
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
                          ? 'Kurtarmaya geldin.'
                          : 'Tekrar hoş geldin.',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ).animate(key: ValueKey(_mode)).fadeIn(duration: 250.ms),
                    const SizedBox(height: 6),
                    Text(
                      _mode == AuthMode.signup
                          ? 'e-Devlet QR kodlu belge ile kimliğini doğrulayalım.'
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
                              organization: _organization,
                              onOrganizationChanged: (v) =>
                                  setState(() => _organization = v),
                              specialization: _specialization,
                              onSpecializationChanged: (v) =>
                                  setState(() => _specialization = v),
                              certificatePdf: _certificatePdf,
                              onPickCertificate: _pickCertificate,
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
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'QR kod ile kimliğin yasal yollarla doğrulanır.',
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
    required this.organization,
    required this.onOrganizationChanged,
    required this.specialization,
    required this.onSpecializationChanged,
    required this.certificatePdf,
    required this.onPickCertificate,
    required this.strength,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String? organization;
  final ValueChanged<String?> onOrganizationChanged;
  final String? specialization;
  final ValueChanged<String?> onSpecializationChanged;
  final PlatformFile? certificatePdf;
  final VoidCallback onPickCertificate;
  final int strength;

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
        const SizedBox(height: 10),
        YanindaTextField(
          label: 'E-posta',
          hint: 'isim@kurum.gov.tr',
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
        const SizedBox(height: 10),
        YanindaDropdown<String>(
          label: 'Uzmanlık alanı (opsiyonel)',
          icon: Icons.medical_services_rounded,
          hint: 'Uzmanlık seç',
          value: specialization,
          onChanged: onSpecializationChanged,
          items: const [
            DropdownMenuItem(
              value: 'arama-kurtarma',
              child: Text('Arama-Kurtarma'),
            ),
            DropdownMenuItem(
              value: 'saglik',
              child: Text('Sağlık / İlk Yardım'),
            ),
            DropdownMenuItem(value: 'lojistik', child: Text('Lojistik')),
            DropdownMenuItem(
              value: 'koordinasyon',
              child: Text('Koordinasyon'),
            ),
            DropdownMenuItem(
              value: 'psikoloji',
              child: Text('Psikolojik Destek'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CertificateUploader(
          file: certificatePdf,
          onTap: onPickCertificate,
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

class _CertificateUploader extends StatelessWidget {
  const _CertificateUploader({required this.file, required this.onTap});

  final PlatformFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: picked
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: picked
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.border,
            width: picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: picked
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                picked ? Icons.check_rounded : Icons.qr_code_2_rounded,
                color: picked ? AppColors.textOnPrimary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    picked
                        ? 'Belge yüklendi'
                        : 'e-Devlet QR PDF\'i yükle',
                    style: AppTypography.bodyLarge.copyWith(
                      color: picked
                          ? AppColors.primary
                          : AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked
                        ? file!.name
                        : 'AKUT/AFAD/Kızılay yetkili belgesi (PDF)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              picked ? Icons.refresh_rounded : Icons.upload_file_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
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
          hint: 'isim@kurum.gov.tr',
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
            InkWell(
              onTap: () => onRememberChanged(!rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
                Icons.medical_services_rounded,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Destek birimi',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
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
