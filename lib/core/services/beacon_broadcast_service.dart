import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/beacon.dart';
import 'device_id_service.dart';
import 'live_beacon_channel.dart';
import 'storage_service.dart';

/// SOS aktif olduğunda mağdurun anonim BLE beacon yayını yaptığı durumu
/// yöneten servis.
///
/// HACKATHON DEMOSU NOTU:
/// flutter_blue_plus 1.x peripheral (advertise) modunu desteklemez. Servis
/// şu an gerçek BLE advertisement yapmaz; bunun yerine:
///   1. Bluetooth adapter'ın açık olduğunu doğrular (kapalıysa kullanıcıdan
///      açmasını ister).
///   2. Anonim ID, kan grubu ve medikal işaretler içeren bir Beacon kaydını
///      Hive'a yazar — kurtarıcı modu (aynı cihazda demo) bu state'i okuyabilir.
///   3. `state` stream'i UI'da "yayında" durumunu gösterir.
///
/// TODO(prod): flutter_ble_peripheral veya yerel platform channel ile gerçek
/// BLE advertisement ekle. Manifest'te BLUETOOTH_ADVERTISE izni hazır.
class BeaconBroadcastService {
  BeaconBroadcastService._();
  static final instance = BeaconBroadcastService._();

  static const _uuid = Uuid();

  final _stateController =
      StreamController<BeaconBroadcastState>.broadcast();
  BeaconBroadcastState _state = const BeaconBroadcastState.idle();

  BeaconBroadcastState get state => _state;
  Stream<BeaconBroadcastState> get stream => _stateController.stream;

  /// Yayını başlatır. Cihaz BLE'yi desteklemiyorsa idle kalır.
  Future<BeaconBroadcastState> start({
    required double lat,
    required double lng,
    String? bloodType,
    List<String> medicalFlags = const <String>[],
    int batteryPercent = 100,
  }) async {
    if (_state.isBroadcasting) return _state;

    final anonId = _generateAnonymousId();
    final beacon = Beacon(
      anonymousId: anonId,
      latitude: lat,
      longitude: lng,
      batteryPercent: batteryPercent,
      bloodType: bloodType ?? '',
      medicalFlags: List<String>.from(medicalFlags),
      broadcastStarted: DateTime.now(),
    );

    try {
      // BLE desteğini kontrol et — Android emulator/iOS simulator'da false dönebilir.
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        debugPrint('ℹ️ Cihaz BLE desteklemiyor — beacon mock modda yayınlanacak.');
      } else {
        // Adapter kapalıysa Android'de aç (iOS'ta otomatik istem gelir).
        if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
          if (defaultTargetPlatform == TargetPlatform.android) {
            await FlutterBluePlus.turnOn();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ BLE adapter kontrolü hata verdi: $e');
    }

    try {
      await StorageService.beaconBox.put('self', beacon);
    } catch (e) {
      debugPrint('⚠️ Beacon Hive\'a yazılamadı: $e');
    }

    // Supabase realtime — diğer cihazlardaki kurtarıcılar yayını anında görür.
    try {
      final deviceId = await DeviceIdService.get();
      await LiveBeaconChannel.instance.upsert(
        deviceId: deviceId,
        beacon: beacon,
      );
    } catch (e) {
      debugPrint('⚠️ Live beacon channel upsert hata: $e');
    }

    _setState(BeaconBroadcastState.broadcasting(beacon: beacon));
    return _state;
  }

  Future<void> stop() async {
    if (!_state.isBroadcasting) return;

    try {
      await StorageService.beaconBox.delete('self');
    } catch (e) {
      debugPrint('⚠️ Beacon Hive\'dan silinemedi: $e');
    }

    try {
      final deviceId = await DeviceIdService.get();
      await LiveBeaconChannel.instance.remove(deviceId);
    } catch (e) {
      debugPrint('⚠️ Live beacon channel remove hata: $e');
    }

    _setState(const BeaconBroadcastState.idle());
  }

  void _setState(BeaconBroadcastState next) {
    _state = next;
    _stateController.add(next);
  }

  /// Kısa, ekrana sığan anonim kimlik (örn: "a3f-91b").
  String _generateAnonymousId() {
    final raw = _uuid.v4().replaceAll('-', '');
    return '${raw.substring(0, 3)}-${raw.substring(3, 6)}';
  }
}

@immutable
class BeaconBroadcastState {
  const BeaconBroadcastState.idle()
      : isBroadcasting = false,
        beacon = null;
  const BeaconBroadcastState.broadcasting({required Beacon this.beacon})
      : isBroadcasting = true;

  final bool isBroadcasting;
  final Beacon? beacon;
}

/// Riverpod provider — UI ve controller'lar bu provider üzerinden erişir.
final beaconBroadcastServiceProvider = Provider<BeaconBroadcastService>((ref) {
  return BeaconBroadcastService.instance;
});

/// Yayın durumunu reactive olarak izlemek için.
final beaconBroadcastStateProvider = StreamProvider<BeaconBroadcastState>((ref) {
  final service = ref.watch(beaconBroadcastServiceProvider);
  return service.stream.asBroadcastStream();
});
