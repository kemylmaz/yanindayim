import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'cached_tile_provider.dart';

class AssemblyMapScreen extends StatefulWidget {
  const AssemblyMapScreen({super.key});

  @override
  State<AssemblyMapScreen> createState() => _AssemblyMapScreenState();
}

class _AssemblyMapScreenState extends State<AssemblyMapScreen> {
  final MapController _mapController = MapController();
  List<_AssemblyArea> _areas = const [];
  _AssemblyArea? _selected;

  // Konum izni yoksa veya alınamadıysa Balıkesir merkez fallback.
  static const _fallbackLocation = LatLng(39.6505, 27.8732);
  LatLng _userLocation = _fallbackLocation;
  bool _gpsReady = false;
  bool _hasArrived = false;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // İzin kontrol + iste
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // sessiz fallback — sabit demo konum kullanılır
      }

      // Servis açık mı?
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      // İlk konum
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _gpsReady = true;
        });
        _mapController.move(_userLocation, 14);
        _resortAreas();
      } catch (_) {
        // İlk lokalizasyon başarısız — stream'e güvenelim
      }

      // Canlı stream — 5m'de bir veya 2 sn'de bir
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _gpsReady = true;
        });
        _checkArrived();
        _resortAreas();
      });
    } catch (_) {
      // sessiz fallback
    }
  }

  void _resortAreas() {
    if (_areas.isEmpty) return;
    final sorted = List<_AssemblyArea>.from(_areas)
      ..sort((a, b) =>
          _distance(_userLocation, a.location)
              .compareTo(_distance(_userLocation, b.location)));
    _areas = sorted;
  }

  /// Seçili hedefe yaklaştık mı? 50m içinde "Ulaştın" feedback ver.
  void _checkArrived() {
    if (_selected == null || _hasArrived) return;
    final d = _distance(_userLocation, _selected!.location);
    if (d < 50) {
      setState(() => _hasArrived = true);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 250), HapticFeedback.heavyImpact);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selected!.name} toplanma alanına ulaştınız!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _loadAreas() async {
    final raw =
        await rootBundle.loadString('assets/maps/assembly_areas.geojson');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;
    final parsed = features
        .map((f) {
          final map = f as Map<String, dynamic>;
          final geometry = map['geometry'] as Map<String, dynamic>;
          final coords = (geometry['coordinates'] as List).cast<num>();
          final props = map['properties'] as Map<String, dynamic>;
          return _AssemblyArea(
            id: props['id'] as String,
            name: props['name'] as String,
            district: props['district'] as String,
            city: props['city'] as String,
            capacity: props['capacity'] as int? ?? 0,
            facilities: (props['facilities'] as List?)?.cast<String>() ??
                const <String>[],
            location: LatLng(coords[1].toDouble(), coords[0].toDouble()),
          );
        })
        .where((a) => a.city.toLowerCase() == 'balikesir')
        .toList();

    parsed.sort((a, b) => _distance(_userLocation, a.location)
        .compareTo(_distance(_userLocation, b.location)));

    if (!mounted) return;
    setState(() => _areas = parsed);
  }

  static double _distance(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, a, b);
  }

  /// Kullanıcı konumundan hedef konuma kuzey-doğu eksenindeki açı (0-360°).
  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  /// Bearing değerini Türkçe yön kelimesine çevir.
  static String _bearingToText(double bearing) {
    const directions = [
      'kuzeye', 'kuzeydoğuya', 'doğuya', 'güneydoğuya',
      'güneye', 'güneybatıya', 'batıya', 'kuzeybatıya',
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  String _humanDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _humanDuration(double meters) {
    // Yürüyüş hızı 5 km/h = 83 m/dk
    final mins = (meters / 83).ceil();
    if (mins < 1) return '< 1 dk';
    if (mins < 60) return '$mins dk';
    final hours = mins ~/ 60;
    final remaining = mins % 60;
    return '$hours sa $remaining dk';
  }

  void _focusArea(_AssemblyArea area) {
    setState(() {
      _selected = area;
      _hasArrived = false;
    });
    _mapController.move(area.location, 15);
  }

  @override
  Widget build(BuildContext context) {
    final nearest = _areas.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 10,
                minZoom: 6,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.appjam.yaninda',
                  maxZoom: 18,
                  tileProvider: CachedTileProvider(),
                ),
                if (_selected != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_userLocation, _selected!.location],
                        strokeWidth: 4.5,
                        color: AppColors.primary,
                        pattern:StrokePattern.dashed(segments: [10, 10]),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation,
                      width: 28,
                      height: 28,
                      child: const _UserDot(),
                    ),
                    ..._areas.map(
                      (area) => Marker(
                        point: area.location,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _focusArea(area),
                          child: _AssemblyMarker(
                            highlighted: _selected?.id == area.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Tile attribution + ofline note
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: _TopBar(
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/victim'),
              ),
            ),
            // Bottom panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: _selected == null
                          ? _NearestList(
                              areas: nearest,
                              distanceTo: (a) => _humanDistance(
                                _distance(_userLocation, a.location),
                              ),
                              gpsReady: _gpsReady,
                              onTap: _focusArea,
                            )
                          : _SelectedAreaPanel(
                              area: _selected!,
                              distanceMeters:
                                  _distance(_userLocation, _selected!.location),
                              distance: _humanDistance(
                                _distance(_userLocation, _selected!.location),
                              ),
                              duration: _humanDuration(
                                _distance(_userLocation, _selected!.location),
                              ),
                              bearingDeg:
                                  _bearing(_userLocation, _selected!.location),
                              bearingText: _bearingToText(
                                _bearing(_userLocation, _selected!.location),
                              ),
                              hasArrived: _hasArrived,
                              onClose: () => setState(() {
                                _selected = null;
                                _hasArrived = false;
                              }),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────── widgets ───────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Toplanma Alanları',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 17,
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Balıkesir · çevrimdışı çalışır',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AFAD',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryDeep, size: 20),
      ),
    );
  }
}

class _UserDot extends StatefulWidget {
  const _UserDot();

  @override
  State<_UserDot> createState() => _UserDotState();
}

class _UserDotState extends State<_UserDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 0.6 + _c.value * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3D7BCC)
                      .withValues(alpha: 0.35 * (1 - _c.value)),
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3D7BCC),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x553D7BCC),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssemblyMarker extends StatelessWidget {
  const _AssemblyMarker({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: highlighted ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.local_florist_rounded,
          color: highlighted ? AppColors.textOnPrimary : AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}

// ──────────────────────────────── bottom panels ─────────────────────────────

class _NearestList extends StatelessWidget {
  const _NearestList({
    required this.areas,
    required this.distanceTo,
    required this.gpsReady,
    required this.onTap,
  });

  final List<_AssemblyArea> areas;
  final String Function(_AssemblyArea) distanceTo;
  final bool gpsReady;
  final void Function(_AssemblyArea) onTap;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 28, height: 2, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'EN YAKIN ÜÇ',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            // GPS durum rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (gpsReady ? AppColors.primary : AppColors.amber)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    gpsReady
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    size: 12,
                    color: gpsReady ? AppColors.primary : AppColors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    gpsReady ? 'GPS aktif' : 'GPS bekleniyor',
                    style: AppTypography.labelSmall.copyWith(
                      color: gpsReady ? AppColors.primary : AppColors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(areas.length, (i) {
          final a = areas[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == areas.length - 1 ? 0 : 10),
            child: _NearestTile(
              area: a,
              distance: distanceTo(a),
              onTap: () => onTap(a),
            ),
          );
        }),
      ],
    );
  }
}

class _NearestTile extends StatelessWidget {
  const _NearestTile({
    required this.area,
    required this.distance,
    required this.onTap,
  });

  final _AssemblyArea area;
  final String distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_florist_rounded,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    area.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${area.district} · ${area.city}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distance,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedAreaPanel extends StatelessWidget {
  const _SelectedAreaPanel({
    required this.area,
    required this.distance,
    required this.distanceMeters,
    required this.bearingDeg,
    required this.bearingText,
    required this.duration,
    required this.hasArrived,
    required this.onClose,
  });

  final _AssemblyArea area;
  final String distance;
  final double distanceMeters;
  final double bearingDeg;
  final String bearingText;
  final String duration;
  final bool hasArrived;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final closeToTarget = distanceMeters < 200;
    final navColor = hasArrived
        ? AppColors.primary
        : (closeToTarget ? AppColors.teal : AppColors.amber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_florist_rounded,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    area.name,
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 18,
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${area.district} · ${area.city}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Yön kartı — pusula oku + adım adım tarif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                navColor.withValues(alpha: 0.12),
                navColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: navColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              // Pusula
              _CompassArrow(
                bearing: bearingDeg,
                color: navColor,
                arrived: hasArrived,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasArrived
                          ? 'Toplanma alanına ulaştın'
                          : '$distance $bearingText yürü',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasArrived
                          ? 'Beacon sinyalin aktifse kurtarıcılar konumunu görür.'
                          : 'Yürüyüş ile yaklaşık $duration · çevrimdışı tarif',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Chip(
              icon: Icons.straighten_rounded,
              label: distance,
              color: AppColors.primary,
            ),
            _Chip(
              icon: Icons.directions_walk_rounded,
              label: duration,
              color: navColor,
            ),
            _Chip(
              icon: Icons.groups_rounded,
              label: '~${area.capacity} kişi',
              color: AppColors.teal,
            ),
          ],
        ),
        if (area.facilities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: area.facilities
                .map((f) => _FacilityChip(facility: f))
                .toList(),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

/// Hedef yönüne işaret eden ok. Bearing 0=kuzey, 90=doğu...
class _CompassArrow extends StatelessWidget {
  const _CompassArrow({
    required this.bearing,
    required this.color,
    required this.arrived,
  });

  final double bearing;
  final Color color;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      child: Center(
        child: arrived
            ? Icon(Icons.check_rounded, color: color, size: 30)
            : Transform.rotate(
                angle: bearing * math.pi / 180,
                child: Icon(
                  Icons.navigation_rounded,
                  color: color,
                  size: 30,
                ),
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.facility});

  final String facility;

  static const _icons = <String, IconData>{
    'su': Icons.water_drop_rounded,
    'tuvalet': Icons.wc_rounded,
    'elektrik': Icons.electric_bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[facility] ?? Icons.check_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryDeep),
          const SizedBox(width: 4),
          Text(
            facility,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── data ──────────────────────────────────────

class _AssemblyArea {
  const _AssemblyArea({
    required this.id,
    required this.name,
    required this.district,
    required this.city,
    required this.capacity,
    required this.facilities,
    required this.location,
  });

  final String id;
  final String name;
  final String district;
  final String city;
  final int capacity;
  final List<String> facilities;
  final LatLng location;
}
