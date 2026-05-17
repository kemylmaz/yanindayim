import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/victim_beacon.dart';
import '../../../core/services/beacon_scanner_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// AR Beacon Tarama — kamerayı açıp etrafa baktığında yakındaki SOS yayını
/// yapan mağdurları konumlarına göre overlay'lerle gösterir. Pusula
/// (manyetometre) + GPS + beacon koordinatlarını birleştirerek FOV içindeki
/// hedefleri canlı işaretler.
class RescuerArScreen extends StatefulWidget {
  const RescuerArScreen({super.key});

  @override
  State<RescuerArScreen> createState() => _RescuerArScreenState();
}

class _RescuerArScreenState extends State<RescuerArScreen> {
  CameraController? _cam;
  bool _initializing = true;
  String? _errorMessage;

  double _heading = 0.0; // Telefonun baktığı yön (0 = kuzey, derece)
  LatLng _userLocation = const LatLng(39.6505, 27.8732); // fallback
  bool _gpsReady = false;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<List<VictimBeacon>>? _beaconSub;

  List<VictimBeacon> _beacons = const [];

  // Kamera yatay görüş açısı (typical phone wide camera ~65-70°)
  static const double _cameraFovDeg = 60.0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) Kamera izni
    var camStatus = await Permission.camera.status;
    if (!camStatus.isGranted) {
      camStatus = await Permission.camera.request();
    }
    if (!camStatus.isGranted) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kamera izni verilmedi. Ayarlardan açabilirsin.';
          _initializing = false;
        });
      }
      return;
    }

    // 2) Konum izni
    try {
      var locStatus = await Geolocator.checkPermission();
      if (locStatus == LocationPermission.denied) {
        locStatus = await Geolocator.requestPermission();
      }
      if (locStatus != LocationPermission.denied &&
          locStatus != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
            _gpsReady = true;
          });
        }
        _posSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((p) {
          if (!mounted) return;
          setState(() => _userLocation = LatLng(p.latitude, p.longitude));
        });
      }
    } catch (_) {}

    // 3) Pusula stream
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null || !mounted) return;
      setState(() => _heading = h);
    });

    // 4) Beacon stream
    _beaconSub = BeaconScannerService.instance.scan().listen((list) {
      if (!mounted) return;
      setState(() => _beacons = list);
    });

    // 5) Kamera başlat
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw 'Kamera bulunamadı';
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cam = controller;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kamera başlatılamadı: $e';
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _posSub?.cancel();
    _beaconSub?.cancel();
    _cam?.dispose();
    super.dispose();
  }

  /// İki nokta arasında bearing (kuzeye göre açı, 0-360°).
  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const d = Distance();
    return d.as(LengthUnit.Meter, a, b);
  }

  /// Hedefin telefonun FOV içinde olup olmadığını ve ekranda nereye düşeceğini
  /// hesaplar. -1..+1 → ekranın yatay yüzdesi (sol kenar -1, sağ +1, orta 0).
  double? _xPosition(double targetBearing) {
    var delta = targetBearing - _heading;
    while (delta > 180) {
      delta -= 360;
    }
    while (delta < -180) {
      delta += 360;
    }
    if (delta.abs() > _cameraFovDeg / 2) return null;
    return delta / (_cameraFovDeg / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera preview
          if (_cam != null && _cam!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cam!.value.previewSize?.height ?? 1080,
                  height: _cam!.value.previewSize?.width ?? 1920,
                  child: CameraPreview(_cam!),
                ),
              ),
            )
          else if (_initializing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            _ErrorState(message: _errorMessage ?? 'Bilinmeyen hata'),

          // Crosshair (orta nokta)
          if (_cam != null && _cam!.value.isInitialized)
            const Center(child: _Crosshair()),

          // Beacon overlay'leri
          if (_cam != null && _cam!.value.isInitialized)
            _BeaconOverlay(
              beacons: _beacons,
              userLocation: _userLocation,
              heading: _heading,
              bearingFn: _bearing,
              distanceFn: _distanceMeters,
              xPositionFn: _xPosition,
            ),

          // Üst bilgi paneli
          if (_cam != null && _cam!.value.isInitialized)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _TopHud(
                    heading: _heading,
                    beaconCount: _beacons.length,
                    gpsReady: _gpsReady,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── overlay ────────────────────────────────────

class _BeaconOverlay extends StatelessWidget {
  const _BeaconOverlay({
    required this.beacons,
    required this.userLocation,
    required this.heading,
    required this.bearingFn,
    required this.distanceFn,
    required this.xPositionFn,
  });

  final List<VictimBeacon> beacons;
  final LatLng userLocation;
  final double heading;
  final double Function(LatLng, LatLng) bearingFn;
  final double Function(LatLng, LatLng) distanceFn;
  final double? Function(double) xPositionFn;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final markers = <Widget>[];

    for (final b in beacons) {
      final bearing = bearingFn(userLocation, b.location);
      final distance = distanceFn(userLocation, b.location);
      // 500m'den uzak hedefleri gösterme — çok küçük olur, gürültü yapar.
      if (distance > 500) continue;
      final xPct = xPositionFn(bearing);
      if (xPct == null) continue;

      // Ekran konumu: yatay FOV → x; mesafe arttıkça ufakta gözüksün (y aşağı)
      final x = (size.width / 2) + xPct * (size.width / 2);
      // Mesafeye göre dikey pozisyon: yakındaysa ortada, uzaktaysa daha yukarı
      final yNorm = (distance / 500).clamp(0.0, 1.0);
      final y = size.height * (0.35 + yNorm * 0.10);
      // Mesafeye göre boyut
      final scale = (1.0 - yNorm * 0.55).clamp(0.45, 1.0);

      markers.add(
        Positioned(
          left: x - 60 * scale,
          top: y - 40 * scale,
          width: 120 * scale,
          child: Transform.scale(
            scale: scale,
            child: _BeaconMarker(beacon: b, distance: distance),
          ),
        ),
      );
    }

    return Stack(children: markers);
  }
}

class _BeaconMarker extends StatelessWidget {
  const _BeaconMarker({required this.beacon, required this.distance});

  final VictimBeacon beacon;
  final double distance;

  String get _distanceLabel =>
      distance < 1000 ? '${distance.round()}m' : '${(distance / 1000).toStringAsFixed(1)}km';

  @override
  Widget build(BuildContext context) {
    final urgency = beacon.batteryPercent < 15
        ? AppColors.critical
        : beacon.batteryPercent < 35
            ? AppColors.amber
            : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: urgency, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.front_hand_rounded, color: urgency, size: 14),
              const SizedBox(width: 4),
              Text(
                beacon.anonymousId,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 2,
          height: 28,
          color: urgency,
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: urgency,
            boxShadow: [
              BoxShadow(
                color: urgency.withValues(alpha: 0.7),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: urgency,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _distanceLabel,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────── top HUD ────────────────────────────────────

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.heading,
    required this.beaconCount,
    required this.gpsReady,
    required this.onBack,
  });

  final double heading;
  final int beaconCount;
  final bool gpsReady;
  final VoidCallback onBack;

  String get _compassLabel {
    const dirs = ['K', 'KD', 'D', 'GD', 'G', 'GB', 'B', 'KB'];
    final i = ((heading + 22.5) / 45).floor() % 8;
    return '${dirs[i]} · ${heading.round()}°';
  }

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
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'AR Tarama',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _hudChip(
                  icon: Icons.explore_rounded,
                  label: _compassLabel,
                ),
                const SizedBox(width: 6),
                _hudChip(
                  icon: Icons.front_hand_rounded,
                  label: '$beaconCount',
                ),
                const SizedBox(width: 6),
                Icon(
                  gpsReady
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  size: 14,
                  color: gpsReady ? AppColors.primaryLight : AppColors.amber,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hudChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── error ──────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: AppColors.amber,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
