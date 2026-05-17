import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mağdurun acil durum sağlık kartı. Enkaz altında ya da bilinçsiz iken
/// kurtarıcının saniyeler içinde okuyabilmesi için: kan grubu, alerjiler,
/// kronik hastalıklar, kullanılan ilaçlar ve acil kişi bilgileri.
///
/// SharedPreferences'a JSON olarak saklanır (Hive entity gerektirmez).
@immutable
class HealthCard {
  const HealthCard({
    this.fullName = '',
    this.dateOfBirth,
    this.bloodType,
    this.allergies = const <String>[],
    this.medications = const <String>[],
    this.chronicConditions = const <String>[],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.doctorName = '',
    this.doctorPhone = '',
    this.notes = '',
  });

  final String fullName;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medications;
  final List<String> chronicConditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String doctorName;
  final String doctorPhone;
  final String notes;

  bool get isEmpty =>
      fullName.isEmpty &&
      bloodType == null &&
      allergies.isEmpty &&
      medications.isEmpty &&
      chronicConditions.isEmpty &&
      emergencyContactPhone.isEmpty;

  HealthCard copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    List<String>? chronicConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? doctorName,
    String? doctorPhone,
    String? notes,
  }) {
    return HealthCard(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'bloodType': bloodType,
        'allergies': allergies,
        'medications': medications,
        'chronicConditions': chronicConditions,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'doctorName': doctorName,
        'doctorPhone': doctorPhone,
        'notes': notes,
      };

  factory HealthCard.fromJson(Map<String, dynamic> json) => HealthCard(
        fullName: (json['fullName'] as String?) ?? '',
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        bloodType: json['bloodType'] as String?,
        allergies: ((json['allergies'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        medications: ((json['medications'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        chronicConditions: ((json['chronicConditions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        emergencyContactName:
            (json['emergencyContactName'] as String?) ?? '',
        emergencyContactPhone:
            (json['emergencyContactPhone'] as String?) ?? '',
        doctorName: (json['doctorName'] as String?) ?? '',
        doctorPhone: (json['doctorPhone'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
      );

  /// Kurtarıcının QR kodla okuduğu kompakt metin — internetsiz çalışır.
  String toEmergencySummary() {
    final lines = <String>[
      if (fullName.isNotEmpty) 'Ad: $fullName',
      if (bloodType != null && bloodType!.isNotEmpty) 'Kan: $bloodType',
      if (allergies.isNotEmpty) 'Alerji: ${allergies.join(", ")}',
      if (chronicConditions.isNotEmpty)
        'Kronik: ${chronicConditions.join(", ")}',
      if (medications.isNotEmpty) 'İlaç: ${medications.join(", ")}',
      if (emergencyContactPhone.isNotEmpty)
        'Acil iletişim: $emergencyContactName $emergencyContactPhone'.trim(),
      if (doctorPhone.isNotEmpty)
        'Doktor: $doctorName $doctorPhone'.trim(),
    ];
    return lines.join('\n');
  }
}

class HealthCardService {
  HealthCardService._();
  static final instance = HealthCardService._();

  static const _key = 'health_card_v1';

  Future<HealthCard> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const HealthCard();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return HealthCard.fromJson(json);
    } catch (e) {
      debugPrint('⚠️ HealthCard load hata: $e');
      return const HealthCard();
    }
  }

  Future<void> save(HealthCard card) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(card.toJson()));
    } catch (e) {
      debugPrint('⚠️ HealthCard save hata: $e');
    }
  }
}

final healthCardServiceProvider = Provider<HealthCardService>((ref) {
  return HealthCardService.instance;
});

/// Reactive card state — değişince UI yenilenir.
class HealthCardController extends StateNotifier<HealthCard> {
  HealthCardController(this._service) : super(const HealthCard()) {
    _service.load().then((c) {
      if (mounted) state = c;
    });
  }

  final HealthCardService _service;

  Future<void> update(HealthCard card) async {
    state = card;
    await _service.save(card);
  }
}

final healthCardProvider =
    StateNotifierProvider<HealthCardController, HealthCard>((ref) {
  return HealthCardController(ref.watch(healthCardServiceProvider));
});
