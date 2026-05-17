import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/checkin_contacts_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  // Hazır mesaj şablonları.
  static const _messageTemplates = <_MessageTemplate>[
    _MessageTemplate(
      key: 'safe',
      icon: Icons.check_circle_rounded,
      label: 'Güvendeyim',
      color: AppColors.primary,
      body: 'Güvendeyim. Endişelenme. Yanındayım uygulamasından otomatik bildirim.',
    ),
    _MessageTemplate(
      key: 'help',
      icon: Icons.warning_amber_rounded,
      label: 'Yardım lazım',
      color: AppColors.amber,
      body: 'Yardıma ihtiyacım var. Konumumu kontrol et, ulaşmaya çalışıyorum. Yanındayım uygulamasından.',
    ),
    _MessageTemplate(
      key: 'meeting',
      icon: Icons.place_rounded,
      label: 'Buluşma noktasına git',
      color: AppColors.teal,
      body: 'Buluşma noktasına gidiyorum. Sen de aynı yere gel. Yanındayım uygulamasından.',
    ),
  ];

  _MessageTemplate _selectedTemplate = _messageTemplates.first;
  final Set<String> _sentTo = {}; // Bu oturumda gönderilen kişi ID'leri

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(checkinContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go('/victim'),
                    onAdd: () => _openAddDialog(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Güvende olduğunu bildir',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.primaryDeep,
                      height: 1.1,
                      fontSize: 26,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Hazır mesajını seç, kişilerine WhatsApp veya SMS ile tek tıkla gönder.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 16),
                  _MessageTemplatePicker(
                    templates: _messageTemplates,
                    selected: _selectedTemplate,
                    onChanged: (t) => setState(() {
                      _selectedTemplate = t;
                      _sentTo.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel(
                    label: 'KİŞİLERİM',
                    trailing: contacts.isEmpty
                        ? null
                        : '${contacts.length} kayıtlı',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: contacts.isEmpty
                        ? _EmptyState(onAdd: _openAddDialog)
                        : ListView.separated(
                            itemCount: contacts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final c = contacts[i];
                              return _ContactRow(
                                contact: c,
                                sent: _sentTo.contains(c.id),
                                onDelete: () => _confirmDelete(c),
                              ).animate(delay: (i * 60).ms).fadeIn(
                                    duration: 300.ms,
                                  );
                            },
                          ),
                  ),
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _BulkSendButton(
                      label: 'Mesaj gönder',
                      icon: Icons.send_rounded,
                      onTap: () => _openSendSheet(contacts),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Toplu gönderim modal'ı: kullanıcı kanal(lar)ı seçer → uygulama
  /// WhatsApp + SMS'i sırayla açar (her ikisi de mümkün).
  Future<void> _openSendSheet(List<CheckinContact> contacts) async {
    if (contacts.isEmpty) return;
    final choice = await showModalBottomSheet<_SendChannel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChannelPickerSheet(
        contactCount: contacts.length,
        template: _selectedTemplate,
      ),
    );
    if (choice == null) return;

    switch (choice) {
      case _SendChannel.whatsapp:
        await _sendBulkWhatsApp(contacts);
      case _SendChannel.sms:
        await _sendBulkSms(contacts);
      case _SendChannel.both:
        await _sendBulkSms(contacts);
        // Kullanıcı SMS app'inden döndükten sonra WhatsApp'ı aç (kısa delay).
        await Future.delayed(const Duration(milliseconds: 600));
        await _sendBulkWhatsApp(contacts);
    }
  }

  /// Her kişi için WhatsApp link'i sırayla açılır. Kullanıcı her birinde
  /// "Gönder" diyince WhatsApp'tan app'e döner, sıradakine geçilir.
  Future<void> _sendBulkWhatsApp(List<CheckinContact> contacts) async {
    final body = Uri.encodeComponent(_selectedTemplate.body);
    for (final c in contacts) {
      final uri = Uri.parse('https://wa.me/${c.cleanPhone}?text=$body');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        setState(() => _sentTo.add(c.id));
      } catch (e) {
        _showError('WhatsApp açılamadı (${c.name}).');
        continue;
      }
      // Kullanıcının WhatsApp ekranını kapatması için bekleme süresi.
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  /// Tüm kişilere tek SMS draft'ı açar (multi-recipient).
  Future<void> _sendBulkSms(List<CheckinContact> contacts) async {
    final phones = contacts.map((c) => c.cleanPhone).join(',');
    final body = Uri.encodeComponent(_selectedTemplate.body);
    final uri = Uri.parse('sms:$phones?body=$body');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _sentTo.addAll(contacts.map((c) => c.id)));
    } catch (e) {
      _showError('SMS uygulaması açılamadı: $e');
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

  Future<void> _openAddDialog() async {
    final choice = await showModalBottomSheet<_AddSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSourceSheet(),
    );
    if (choice == null) return;

    switch (choice) {
      case _AddSource.fromContacts:
        await _pickFromContacts();
      case _AddSource.manual:
        if (!mounted) return;
        final result = await showModalBottomSheet<CheckinContact>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const _AddContactSheet(),
        );
        if (result != null) {
          await ref.read(checkinContactsProvider.notifier).add(result);
        }
    }
  }

  Future<void> _pickFromContacts() async {
    try {
      // 1) İzin durumu kontrol et — permission_handler ile native dialog tetikle.
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
      }
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showError(
          'Rehber izni kalıcı reddedildi. Ayarlardan açabilirsin.',
        );
        await openAppSettings();
        return;
      }
      if (!status.isGranted) {
        _showError('Rehber izni verilmedi.');
        return;
      }

      // 2) flutter_contacts'a da izni doğrula (bazı cihazlarda ayrı kontrol).
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        _showError('Rehbere erişilemedi.');
        return;
      }

      // 3) Sistem picker'ını aç.
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return; // kullanıcı iptal etti

      // 4) Telefon numarasını çek.
      final full = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
      );
      final phones = full?.phones ?? const [];
      if (phones.isEmpty) {
        _showError('${contact.displayName} için kayıtlı telefon yok.');
        return;
      }
      final phone = phones.first.number.trim();
      final name = contact.displayName.trim().isEmpty
          ? phone
          : contact.displayName.trim();

      await ref.read(checkinContactsProvider.notifier).add(
            CheckinContact(
              id: const Uuid().v4(),
              name: name,
              phone: phone,
            ),
          );
    } catch (e) {
      _showError('Rehberden kişi alınamadı: $e');
    }
  }

  Future<void> _confirmDelete(CheckinContact c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Kişiyi sil?',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.primaryDeep,
          ),
        ),
        content: Text(
          '${c.name} listenden silinecek.',
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
              'Sil',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.critical,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checkinContactsProvider.notifier).remove(c.id);
    }
  }
}

// ──────────────────────────────── header ────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

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
        Expanded(
          child: Text(
            'Güvendeyim',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primarySoft, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ekle',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── message picker ────────────────────────────

class _MessageTemplate {
  const _MessageTemplate({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.body,
  });

  final String key;
  final IconData icon;
  final String label;
  final Color color;
  final String body;
}

class _MessageTemplatePicker extends StatelessWidget {
  const _MessageTemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  final List<_MessageTemplate> templates;
  final _MessageTemplate selected;
  final ValueChanged<_MessageTemplate> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'GÖNDERECEĞİN MESAJ'),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = templates[i];
              final isSelected = t.key == selected.key;
              return GestureDetector(
                onTap: () => onChanged(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 130,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.color
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? t.color : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: t.color.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        t.icon,
                        color: isSelected ? Colors.white : t.color,
                        size: 22,
                      ),
                      Text(
                        t.label,
                        style: AppTypography.labelLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── contact row ───────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.sent,
    required this.onDelete,
  });

  final CheckinContact contact;
  final bool sent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sent
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: sent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primarySoft, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                contact.name.isEmpty
                    ? '?'
                    : contact.name.substring(0, 1).toUpperCase(),
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sent) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  contact.phone,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Sil
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Sil',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── empty state ───────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primarySoft.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Henüz kişi eklemedin',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aile ve arkadaşlarını ekle; acil durumda tek tıkla bilgilendirirsin.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primarySoft, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'İlk kişiyi ekle',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
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

// ──────────────────────────────── channel picker ────────────────────────────

enum _SendChannel { whatsapp, sms, both }

class _ChannelPickerSheet extends StatelessWidget {
  const _ChannelPickerSheet({
    required this.contactCount,
    required this.template,
  });

  final int contactCount;
  final _MessageTemplate template;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nasıl gönderilsin?',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$contactCount kişiye → "${template.label}"',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _ChannelTile(
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: 'Her kişi için ayrı pencerede WhatsApp açılır',
            onTap: () => Navigator.pop(context, _SendChannel.whatsapp),
          ),
          const SizedBox(height: 10),
          _ChannelTile(
            icon: Icons.sms_rounded,
            iconColor: AppColors.primary,
            title: 'SMS',
            subtitle: 'Tüm kişilere tek SMS draftı açılır',
            onTap: () => Navigator.pop(context, _SendChannel.sms),
          ),
          const SizedBox(height: 10),
          _ChannelTile(
            icon: Icons.all_inclusive_rounded,
            iconColor: AppColors.amber,
            title: 'Her ikisi',
            subtitle: 'Önce SMS, sonra her kişi için WhatsApp',
            onTap: () => Navigator.pop(context, _SendChannel.both),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────── add source sheet ──────────────────────────

enum _AddSource { fromContacts, manual }

class _AddSourceSheet extends StatelessWidget {
  const _AddSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kişi nasıl eklensin?',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _ChannelTile(
            icon: Icons.contacts_rounded,
            iconColor: AppColors.primary,
            title: 'Rehberden seç',
            subtitle: 'Telefon rehberinden hızlıca al — internet gerekmez',
            onTap: () => Navigator.pop(context, _AddSource.fromContacts),
          ),
          const SizedBox(height: 10),
          _ChannelTile(
            icon: Icons.edit_rounded,
            iconColor: AppColors.teal,
            title: 'Manuel gir',
            subtitle: 'Ad ve numarayı kendin yaz',
            onTap: () => Navigator.pop(context, _AddSource.manual),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── add sheet ─────────────────────────────────

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    Navigator.pop(
      context,
      CheckinContact(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Yeni kişi',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acil durumda tek tıkla mesaj göndereceğin kişiyi ekle.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Ad / yakınlık',
              hint: 'Annem, Ahmet, Eşim...',
              controller: _nameCtrl,
              icon: Icons.person_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            _LabeledField(
              label: 'Telefon',
              hint: '+90 555 ...',
              controller: _phoneCtrl,
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\(\)\-]')),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: AppTypography.buttonMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primarySoft, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Kaydet',
                          style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    this.textCapitalization,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

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
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  textCapitalization:
                      textCapitalization ?? TextCapitalization.none,
                  inputFormatters: inputFormatters,
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

// ──────────────────────────────── shared bits ───────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

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
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _BulkSendButton extends StatefulWidget {
  const _BulkSendButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_BulkSendButton> createState() => _BulkSendButtonState();
}

class _BulkSendButtonState extends State<_BulkSendButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 16),
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
