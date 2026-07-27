import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/beacon.dart';
import '../models/victim_beacon.dart';
import 'ble_constants.dart';
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
    StreamSubscription<List<ScanResult>>? bleSub;
    var remoteBeacons = const <VictimBeacon>[];
    // BLE üzerinden gerçek zamanlı çevredeki cihazların anonim ID → beacon map'i.
    final bleBeacons = <String, VictimBeacon>{};

    void emit() {
      // Sıra: BLE (çevrimdışı yakın), uzak (Supabase), self (Hive), mock.
      final list = <VictimBeacon>[
        ...bleBeacons.values,
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
      try {
        hiveSub =
            StorageService.beaconBox.watch(key: _kSelfBeaconKey).listen((_) {
          emit();
        });
      } catch (_) {}
      () async {
        try {
          final myDeviceId = await DeviceIdService.get();
          remoteSub = LiveBeaconChannel.instance
              .streamOthers(myDeviceId)
              .listen((others) {
            remoteBeacons = others;
            emit();
          });
        } catch (_) {}
      }();

      // Gerçek BLE scan — yakındaki yayın yapan mağdurları çevrimdışı yakala.
      _startBleScan(
        onResult: (beacon) {
          bleBeacons[beacon.anonymousId] = beacon;
          emit();
        },
      ).then((sub) => bleSub = sub);
    };

    controller.onCancel = () {
      mutateTimer?.cancel();
      hiveSub?.cancel();
      remoteSub?.cancel();
      bleSub?.cancel();
      _stopBleScan();
    };

    return controller.stream;
  }

  /// flutter_blue_plus üzerinden Yanındayım servis UUID'sini filtreleyerek
  /// çevreyi tarar. Her advertisement geldikçe parse edip [onResult] çağırır.
  Future<StreamSubscription<List<ScanResult>>?> _startBleScan({
    required void Function(VictimBeacon) onResult,
  }) async {
    try {
      // İzinler (Android 12+)
      final perms = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (perms.values.any((s) => !s.isGranted)) {
        debugPrint('⚠️ BLE scan izni verilmedi.');
        return null;
      }

      if (!await FlutterBluePlus.isSupported) {
        debugPrint('ℹ️ Cihaz BLE desteklemiyor (scan).');
        return null;
      }

      // Sürekli tarama başlat (timeout 0 = devam etsin).
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuidFull)],
        continuousUpdates: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );

      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final beacon = _parseScanResult(r);
          if (beacon != null) onResult(beacon);
        }
      });
      debugPrint('✅ BLE scan başladı (servis UUID filter)');
      return sub;
    } catch (e) {
      debugPrint('⚠️ BLE scan başlatılamadı: $e');
      return null;
    }
  }

  Future<void> _stopBleScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }

  /// Tek bir advertisement'ı VictimBeacon'a dönüştürür.
  VictimBeacon? _parseScanResult(ScanResult result) {
    final adv = result.advertisementData;
    final name = adv.advName;
    if (!name.startsWith(BleConstants.localNamePrefix)) return null;
    final anonId = name.substring(BleConstants.localNamePrefix.length);
    if (anonId.isEmpty) return null;

    String? bloodType;
    int battery = 100;
    final mfg = adv.manufacturerData[BleConstants.manufacturerId];
    if (mfg != null && mfg.length >= 2) {
      bloodType = BleConstants.bloodTypeFromCode(mfg[0]);
      battery = mfg[1].clamp(0, 100);
    }

    // BLE'den konum gelmez — kullanıcının yakınındaki bilinen merkez varsayılır.
    return VictimBeacon(
      anonymousId: anonId,
      location: _kDemoCenter,
      batteryPercent: battery,
      bloodType: bloodType,
      medicalFlags: const <String>[],
      broadcastStarted: DateTime.now(),
      lastSeen: DateTime.now(),
      rssi: result.rssi,
    );
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

  /// Demo için tek bir sahte mağdur: "Emir". Gerçek demo iki telefonla
  /// yapıldığında Supabase realtime kanalından gelen ikinci telefonun yayını
  /// otomatik bu listeye eklenir.
  List<VictimBeacon> _generateInitialBeacons() {
    final now = DateTime.now();
    return [
      VictimBeacon(
        anonymousId: 'Emir',
        location: _offsetLatLng(_kDemoCenter, 35, 60),
        batteryPercent: 72,
        bloodType: 'A+',
        medicalFlags: const ['astım'],
        broadcastStarted: now.subtract(const Duration(minutes: 14)),
        lastSeen: now,
        rssi: -62,
      ),
    ];
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
