import 'dart:async';
import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../models/beacon.dart';
import '../models/victim_beacon.dart';
import 'device_id_service.dart';
import 'live_beacon_channel.dart';
import 'storage_service.dart';

/// BLE Beacon tarama servisi.
///
/// Hackathon demosu için MOCK + LIVE hibrit:
///   • Mock: Sabit 5 sahte mağdur beacon'ı yayar (RSSI/pil mutate edilir).
///   • Live: Mağdur tarafından SOS başlatıldığında `BeaconBroadcastService`
///     Hive'a yazdığı self beacon'ı yakalayıp listeye ekler — kurtarıcı
///     haritasında o noktayı gerçek zamanlı gösterir.
///
/// Production: flutter_blue_plus.startScan ile değiştirilecek; advertise
/// payload'ı parse edilip aynı VictimBeacon yapısına dönüştürülecek.
class BeaconScannerService {
  BeaconScannerService._();
  static final instance = BeaconScannerService._();

  // Balıkesir Atatürk Parkı civarı — harita ekranı ile aynı referans nokta.
  static const _kDemoCenter = LatLng(39.6505, 27.8732);

  // Hive'daki self beacon kaydının anahtarı (BeaconBroadcastService ile aynı).
  static const _kSelfBeaconKey = 'self';

  Stream<List<VictimBeacon>> scan() {
    final mocks = _generateInitialBeacons();
    final controller = StreamController<List<VictimBeacon>>();
    Timer? mutateTimer;
    StreamSubscription<BoxEvent>? hiveSub;
    StreamSubscription<List<VictimBeacon>>? remoteSub;
    var remoteBeacons = const <VictimBeacon>[];

    void emit() {
      // Sıra: önce uzak (Supabase realtime), sonra self (Hive), sonra mock'lar.
      final list = <VictimBeacon>[
        ...remoteBeacons,
      ];
      final self = _readSelf();
      if (self != null) list.add(self);
      list.addAll(mocks);
      controller.add(list);
    }

    controller.onListen = () {
      emit();
      mutateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _mutate(mocks);
        emit();
      });
      // Hive'daki self beacon değişimlerini canlı izle (aynı cihaz demosu).
      try {
        hiveSub =
            StorageService.beaconBox.watch(key: _kSelfBeaconKey).listen((_) {
          emit();
        });
      } catch (e) {
        // beaconBox açık değilse (henüz init olmamış) sessizce geç.
      }
      // Supabase realtime — diğer cihazlardan yayın yapan mağdurları dinle.
      () async {
        try {
          final myDeviceId = await DeviceIdService.get();
          remoteSub = LiveBeaconChannel.instance
              .streamOthers(myDeviceId)
              .listen((others) {
            remoteBeacons = others;
            emit();
          });
        } catch (e) {
          // Supabase erişilemiyorsa offline demo modunda çalışmaya devam et.
        }
      }();
    };

    controller.onCancel = () {
      mutateTimer?.cancel();
      hiveSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  /// Hive'dan kaydedilmiş self beacon'ı okur ve VictimBeacon'a dönüştürür.
  /// Yayın yoksa null döner.
  VictimBeacon? _readSelf() {
    try {
      final box = StorageService.beaconBox;
      final raw = box.get(_kSelfBeaconKey);
      if (raw == null) return null;
      return _toVictim(raw);
    } catch (e) {
      return null;
    }
  }

  VictimBeacon _toVictim(Beacon b) {
    return VictimBeacon(
      anonymousId: b.anonymousId,
      location: LatLng(b.latitude, b.longitude),
      batteryPercent: b.batteryPercent,
      bloodType: b.bloodType.isEmpty ? null : b.bloodType,
      medicalFlags: b.medicalFlags,
      broadcastStarted: b.broadcastStarted,
      lastSeen: b.lastSeen ?? DateTime.now(),
      // Self beacon "aynı cihaz" senaryosunda yakın varsayılır — kurtarıcının
      // hemen yanında. Production'da gerçek RSSI gelir.
      rssi: b.rssi ?? -45,
    );
  }

  List<VictimBeacon> _generateInitialBeacons() {
    final rnd = math.Random(42);
    final now = DateTime.now();
    return [
      VictimBeacon(
        anonymousId: 'a3f-91b',
        location: _offsetLatLng(_kDemoCenter, 12, 35),
        batteryPercent: 87,
        bloodType: 'A+',
        medicalFlags: const ['diyabet'],
        broadcastStarted: now.subtract(const Duration(minutes: 24)),
        lastSeen: now,
        rssi: -58,
      ),
      VictimBeacon(
        anonymousId: 'b8e-22c',
        location: _offsetLatLng(_kDemoCenter, 26, 130),
        batteryPercent: 42,
        bloodType: '0-',
        medicalFlags: const ['kalp', 'alerji'],
        broadcastStarted: now.subtract(const Duration(hours: 1, minutes: 12)),
        lastSeen: now,
        rssi: -72,
      ),
      VictimBeacon(
        anonymousId: 'd71-44f',
        location: _offsetLatLng(_kDemoCenter, 48, 220),
        batteryPercent: 12,
        bloodType: 'AB+',
        medicalFlags: const <String>[],
        broadcastStarted:
            now.subtract(const Duration(hours: 3, minutes: 48)),
        lastSeen: now,
        rssi: -83,
      ),
      VictimBeacon(
        anonymousId: 'e5a-08d',
        location: _offsetLatLng(_kDemoCenter, 95, 295),
        batteryPercent: 68,
        bloodType: 'B+',
        medicalFlags: const ['hamile'],
        broadcastStarted: now.subtract(const Duration(minutes: 8)),
        lastSeen: now,
        rssi: -88,
      ),
      _emptyExtra(rnd, now),
    ];
  }

  VictimBeacon _emptyExtra(math.Random rnd, DateTime now) {
    return VictimBeacon(
      anonymousId: 'f02-7e1',
      location: _offsetLatLng(_kDemoCenter, 70, 60),
      batteryPercent: 31,
      bloodType: null,
      medicalFlags: const <String>[],
      broadcastStarted: now.subtract(const Duration(hours: 2)),
      lastSeen: now,
      rssi: -76,
    );
  }

  /// Her tick'te RSSI ve pil seviyesini hafifçe değiştir — canlı tarama hissi.
  void _mutate(List<VictimBeacon> beacons) {
    final rnd = math.Random();
    for (var i = 0; i < beacons.length; i++) {
      final b = beacons[i];
      final newRssi = (b.rssi + rnd.nextInt(7) - 3).clamp(-95, -30);
      final newBattery = (b.batteryPercent - (rnd.nextDouble() < 0.3 ? 1 : 0))
          .clamp(0, 100);
      beacons[i] = b.copyWith(
        rssi: newRssi,
        batteryPercent: newBattery,
        lastSeen: DateTime.now(),
      );
    }
  }

  /// Verilen merkezden, [meters] mesafede, [bearingDeg] yön açısında yeni
  /// koordinat hesaplar.
  LatLng _offsetLatLng(LatLng center, double meters, double bearingDeg) {
    const earthRadius = 6378137.0;
    final bearing = bearingDeg * math.pi / 180;
    final lat = center.latitude * math.pi / 180;
    final lng = center.longitude * math.pi / 180;

    final newLat = math.asin(math.sin(lat) * math.cos(meters / earthRadius) +
        math.cos(lat) * math.sin(meters / earthRadius) * math.cos(bearing));
    final newLng = lng +
        math.atan2(
          math.sin(bearing) *
              math.sin(meters / earthRadius) *
              math.cos(lat),
          math.cos(meters / earthRadius) - math.sin(lat) * math.sin(newLat),
        );

    return LatLng(
      newLat * 180 / math.pi,
      newLng * 180 / math.pi,
    );
  }

  static LatLng get demoCenter => _kDemoCenter;
}
