import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/health_card_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class HealthCardScreen extends ConsumerWidget {
  const HealthCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(healthCardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go('/victim'),
                ),
                Expanded(
                  child: card.isEmpty
                      ? _EmptyState(
                          onCreate: () => _openEditor(context, ref, card),
                        )
                      : _FilledCard(
                          card: card,
                          onEdit: () => _openEditor(context, ref, card),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, HealthCard current) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HealthCardEditor(initial: current),
      ),
    );
  }
}

// ──────────────────────────────── header ────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sağlık Kartım',
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 22,
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Acil durumda kurtarıcı QR ile saniyede okur',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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

// ──────────────────────────────── empty state ───────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.critical, Color(0xFFE07060)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.critical.withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 56,
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 24),
          Text(
            'Bilgilerin enkaz altında hayat kurtarır',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kan grubu, alerjiler, ilaçlar ve acil iletişimini bir kez gir. '
            'Kurtarıcı QR kodu okuduğunda saniyeler içinde doğru müdahale '
            'yapabilir — internet gerekmez.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Sağlık kartımı oluştur',
            icon: Icons.add_rounded,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── filled card ──────────────────────────────

class _FilledCard extends StatelessWidget {
  const _FilledCard({required this.card, required this.onEdit});

  final HealthCard card;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ID Kart benzeri ana kart
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppColors.critical, Color(0xFFE07060)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.critical.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ACİL SAĞLIK KARTI',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              card.fullName.isEmpty ? '—' : card.fullName,
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (card.bloodType != null && card.bloodType!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            card.bloodType!,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.critical,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // QR
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: card.toEmergencySummary(),
                        size: 168,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.critical,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.critical,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Kurtarıcı QR\'ı okutarak medikal bilgilerimi görür',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).moveY(
                begin: 12, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          // Detay satırları
          if (card.allergies.isNotEmpty)
            _DetailSection(
              icon: Icons.warning_amber_rounded,
              title: 'Alerjiler',
              color: AppColors.amber,
              items: card.allergies,
            ),
          if (card.chronicConditions.isNotEmpty)
            _DetailSection(
              icon: Icons.medical_information_rounded,
              title: 'Kronik hastalıklar',
              color: AppColors.teal,
              items: card.chronicConditions,
            ),
          if (card.medications.isNotEmpty)
            _DetailSection(
              icon: Icons.medication_rounded,
              title: 'Kullandığım ilaçlar',
              color: AppColors.primary,
              items: card.medications,
            ),
          if (card.emergencyContactPhone.isNotEmpty)
            _DetailSection(
              icon: Icons.contact_phone_rounded,
              title: 'Acil iletişim',
              color: AppColors.critical,
              items: [
                if (card.emergencyContactName.isNotEmpty)
                  '${card.emergencyContactName} — ${card.emergencyContactPhone}'
                else
                  card.emergencyContactPhone,
              ],
            ),
          if (card.doctorPhone.isNotEmpty)
            _DetailSection(
              icon: Icons.local_hospital_rounded,
              title: 'Doktor',
              color: AppColors.primarySoft,
              items: [
                if (card.doctorName.isNotEmpty)
                  '${card.doctorName} — ${card.doctorPhone}'
                else
                  card.doctorPhone,
              ],
            ),
          if (card.notes.isNotEmpty)
            _DetailSection(
              icon: Icons.notes_rounded,
              title: 'Notlar',
              color: AppColors.primaryDeep,
              items: [card.notes],
            ),

          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'Bilgileri düzenle',
            icon: Icons.edit_rounded,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                ...items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      e,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

// ──────────────────────────────── editor ────────────────────────────────────

class _HealthCardEditor extends ConsumerStatefulWidget {
  const _HealthCardEditor({required this.initial});

  final HealthCard initial;

  @override
  ConsumerState<_HealthCardEditor> createState() => _HealthCardEditorState();
}

class _HealthCardEditorState extends ConsumerState<_HealthCardEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _medicationsCtrl;
  late final TextEditingController _chronicCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  late final TextEditingController _doctorNameCtrl;
  late final TextEditingController _doctorPhoneCtrl;
  late final TextEditingController _notesCtrl;
  String? _bloodType;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nameCtrl = TextEditingController(text: i.fullName);
    _allergiesCtrl = TextEditingController(text: i.allergies.join(', '));
    _medicationsCtrl = TextEditingController(text: i.medications.join(', '));
    _chronicCtrl = TextEditingController(text: i.chronicConditions.join(', '));
    _emergencyNameCtrl =
        TextEditingController(text: i.emergencyContactName);
    _emergencyPhoneCtrl =
        TextEditingController(text: i.emergencyContactPhone);
    _doctorNameCtrl = TextEditingController(text: i.doctorName);
    _doctorPhoneCtrl = TextEditingController(text: i.doctorPhone);
    _notesCtrl = TextEditingController(text: i.notes);
    _bloodType = i.bloodType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _chronicCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String s) => s
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final card = HealthCard(
      fullName: _nameCtrl.text.trim(),
      bloodType: _bloodType,
      allergies: _splitCsv(_allergiesCtrl.text),
      medications: _splitCsv(_medicationsCtrl.text),
      chronicConditions: _splitCsv(_chronicCtrl.text),
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      doctorName: _doctorNameCtrl.text.trim(),
      doctorPhone: _doctorPhoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    await ref.read(healthCardProvider.notifier).update(card);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabeledField(
                          label: 'Ad Soyad',
                          controller: _nameCtrl,
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 10),
                        _BloodTypePicker(
                          value: _bloodType,
                          onChanged: (v) => setState(() => _bloodType = v),
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Alerjiler (virgülle ayır)',
                          hint: 'penisilin, fıstık',
                          controller: _allergiesCtrl,
                          icon: Icons.warning_amber_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Kronik hastalıklar (virgülle ayır)',
                          hint: 'diyabet, hipertansiyon',
                          controller: _chronicCtrl,
                          icon: Icons.medical_information_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Kullandığım ilaçlar (virgülle ayır)',
                          hint: 'Metformin, Aspirin',
                          controller: _medicationsCtrl,
                          icon: Icons.medication_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'ACİL İLETİŞİM',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _LabeledField(
                          label: 'Yakın adı',
                          controller: _emergencyNameCtrl,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Yakın telefonu',
                          hint: '+90...',
                          controller: _emergencyPhoneCtrl,
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'DOKTOR',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _LabeledField(
                          label: 'Doktor adı',
                          controller: _doctorNameCtrl,
                          icon: Icons.local_hospital_rounded,
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Doktor telefonu',
                          controller: _doctorPhoneCtrl,
                          icon: Icons.phone_in_talk_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        _LabeledField(
                          label: 'Ek notlar (opsiyonel)',
                          controller: _notesCtrl,
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        _PrimaryButton(
                          label: 'Kaydet',
                          icon: Icons.check_rounded,
                          onTap: _save,
                        ),
                      ],
                    ),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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

class _BloodTypePicker extends StatelessWidget {
  const _BloodTypePicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _types = ['0+', '0-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bloodtype_rounded,
                  color: AppColors.critical, size: 18),
              const SizedBox(width: 10),
              Text(
                'KAN GRUBU',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _types.map((t) {
              final selected = t == value;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => onChanged(selected ? null : t),
                selectedColor: AppColors.critical,
                backgroundColor: AppColors.primarySurface,
                labelStyle: AppTypography.labelLarge.copyWith(
                  color: selected ? Colors.white : AppColors.primaryDeep,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: selected ? AppColors.critical : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── shared bits ───────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primarySoft, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTypography.buttonLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
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
