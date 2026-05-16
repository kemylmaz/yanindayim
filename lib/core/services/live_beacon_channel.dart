import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/beacon.dart';
import '../models/victim_beacon.dart';

/// Supabase üzerinden çoklu-cihaz arası canlı beacon paylaşımı.
///
/// Mağdur cihazı `upsert` çağrısı ile kendi yayınını ekler; kurtarıcı cihazı
/// `streamOthers` ile diğer cihazların gerçek-zamanlı listesini alır.
///
/// Supabase tablosu (kullanıcı dashboard'da bir kez çalıştırmalı):
///
/// ```sql
/// create table if not exists public.live_beacons (
///   device_id text primary key,
///   anonymous_id text not null,
///   latitude double precision not null,
///   longitude double precision not null,
///   battery_percent integer not null default 100,
///   blood_type text,
///   medical_flags text[] not null default '{}',
///   broadcast_started_at timestamptz not null default now(),
///   last_seen_at timestamptz not null default now()
/// );
///
/// alter table public.live_beacons enable row level security;
/// create policy "demo_read" on public.live_beacons for select using (true);
/// create policy "demo_write" on public.live_beacons
///   for all using (true) with check (true);
///
/// alter publication supabase_realtime add table public.live_beacons;
/// ```
class LiveBeaconChannel {
  LiveBeaconChannel._();
  static final instance = LiveBeaconChannel._();

  static const _table = 'live_beacons';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> upsert({
    required String deviceId,
    required Beacon beacon,
  }) async {
    try {
      await _supabase.from(_table).upsert({
        'device_id': deviceId,
        'anonymous_id': beacon.anonymousId,
        'latitude': beacon.latitude,
        'longitude': beacon.longitude,
        'battery_percent': beacon.batteryPercent,
        'blood_type': beacon.bloodType.isEmpty ? null : beacon.bloodType,
        'medical_flags': beacon.medicalFlags,
        'broadcast_started_at': beacon.broadcastStarted.toIso8601String(),
        'last_seen_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ LiveBeaconChannel.upsert hata: $e');
    }
  }

  Future<void> remove(String deviceId) async {
    try {
      await _supabase.from(_table).delete().eq('device_id', deviceId);
    } catch (e) {
      debugPrint('⚠️ LiveBeaconChannel.remove hata: $e');
    }
  }

  /// Kendi cihazı hariç diğer tüm aktif yayınları realtime stream olarak yay.
  /// VictimBeacon formatında — kurtarıcı tarafı doğrudan harita marker'ı yapar.
  Stream<List<VictimBeacon>> streamOthers(String myDeviceId) {
    return _supabase
        .from(_table)
        .stream(primaryKey: const ['device_id'])
        .map((rows) => rows
            .where((r) => r['device_id'] != myDeviceId)
            .map(_rowToVictim)
            .toList());
  }

  VictimBeacon _rowToVictim(Map<String, dynamic> row) {
    final flagsRaw = row['medical_flags'];
    final flags = flagsRaw is List
        ? flagsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return VictimBeacon(
      anonymousId: row['anonymous_id']?.toString() ?? '???',
      location: LatLng(
        (row['latitude'] as num).toDouble(),
        (row['longitude'] as num).toDouble(),
      ),
      batteryPercent: (row['battery_percent'] as num?)?.toInt() ?? 0,
      bloodType: row['blood_type']?.toString(),
      medicalFlags: flags,
      broadcastStarted:
          DateTime.tryParse(row['broadcast_started_at']?.toString() ?? '') ??
              DateTime.now(),
      lastSeen: DateTime.tryParse(row['last_seen_at']?.toString() ?? '') ??
          DateTime.now(),
      // Supabase üzerinden gelen yayın için "yakın" varsayılır.
      rssi: -50,
    );
  }
}
