import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Güvendeyim için aile / arkadaş kişisi. Her cihazda yerel olarak saklanır,
/// kullanıcı kontrol eder. Telefonun formatı serbest — gönderim sırasında
/// boşluk/parantez temizlenir.
@immutable
class CheckinContact {
  const CheckinContact({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  /// WhatsApp/SMS gönderiminde kullanılacak temiz format (sadece + ve rakam).
  String get cleanPhone => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };

  factory CheckinContact.fromJson(Map<String, dynamic> json) => CheckinContact(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
      );
}

class CheckinContactsService {
  CheckinContactsService._();
  static final instance = CheckinContactsService._();

  static const _key = 'checkin_contacts_v1';

  Future<List<CheckinContact>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CheckinContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ CheckinContacts load hata: $e');
      return const [];
    }
  }

  Future<void> save(List<CheckinContact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(contacts.map((c) => c.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('⚠️ CheckinContacts save hata: $e');
    }
  }
}

final checkinContactsServiceProvider =
    Provider<CheckinContactsService>((ref) {
  return CheckinContactsService.instance;
});

class CheckinContactsController
    extends StateNotifier<List<CheckinContact>> {
  CheckinContactsController(this._service) : super(const []) {
    _service.load().then((list) {
      if (mounted) state = list;
    });
  }

  final CheckinContactsService _service;

  Future<void> add(CheckinContact contact) async {
    final next = [...state, contact];
    state = next;
    await _service.save(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((c) => c.id != id).toList();
    state = next;
    await _service.save(next);
  }
}

final checkinContactsProvider = StateNotifierProvider<
    CheckinContactsController, List<CheckinContact>>((ref) {
  return CheckinContactsController(ref.watch(checkinContactsServiceProvider));
});
