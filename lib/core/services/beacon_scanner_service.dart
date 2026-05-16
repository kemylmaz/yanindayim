import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/victim_beacon.dart';

/// BLE Beacon tarama servisi.
///
/// Hackathon demosu için MOCK implementation — sahte mağdur beacon'larını
/// stream olarak yayar. Konum etrafında 4 sahte yayın oluşturur, RSSI ve
/// pil seviyeleri zamanla değişir (gerçekçi olma hissi için).
///
/// Production: flutter_blue_plus.startScan ile değiştirilecek.
class BeaconScannerService {
  BeaconScannerService._();
  static final instance = BeaconScannerService._();

  static const _kDemoCenter = LatLng(41.0117, 28.9810);

  Stream<List<VictimBeacon>> scan() {
    final beacons = _generateInitialBeacons();
    final controller = StreamController<List<VictimBeacon>>();
    Timer? timer;

    controller.onListen = () {
      controller.add(beacons);
      timer = Timer.periodic(const Duration(seconds: 3), (_) {
        _mutate(beacons);
        controller.add(List<VictimBeacon>.from(beacons));
      });
    };

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
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
