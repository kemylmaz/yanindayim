import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// BLE Beacon yayını veren mağdurun durumu.
/// Hackathon demosu için mock data ile doldurulur; production'da
/// flutter_blue_plus advertisement paketinden gelir.
@immutable
class VictimBeacon {
  const VictimBeacon({
    required this.anonymousId,
    required this.location,
    required this.batteryPercent,
    required this.broadcastStarted,
    required this.lastSeen,
    required this.rssi,
    this.bloodType,
    this.medicalFlags = const <String>[],
  });

  final String anonymousId; // UUID v4 short
  final LatLng location; // Son bilinen GPS konumu
  final int batteryPercent; // 0-100
  final String? bloodType;
  final List<String> medicalFlags; // ["diyabet", "kalp", "alerji"...]
  final DateTime broadcastStarted;
  final DateTime lastSeen;
  final int rssi; // Sinyal gücü, -100 (çok uzak) ile -30 (çok yakın)

  Duration get broadcastDuration => DateTime.now().difference(broadcastStarted);

  bool get isCritical => batteryPercent < 15;
  bool get isFresh => DateTime.now().difference(lastSeen).inSeconds < 30;

  VictimBeacon copyWith({
    int? batteryPercent,
    DateTime? lastSeen,
    int? rssi,
  }) {
    return VictimBeacon(
      anonymousId: anonymousId,
      location: location,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      bloodType: bloodType,
      medicalFlags: medicalFlags,
      broadcastStarted: broadcastStarted,
      lastSeen: lastSeen ?? this.lastSeen,
      rssi: rssi ?? this.rssi,
    );
  }
}
