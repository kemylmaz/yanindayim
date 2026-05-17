import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/victim_beacon.dart';
import '../../../core/services/beacon_scanner_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../victim/map/cached_tile_provider.dart';

class RescuerHomeScreen extends StatefulWidget {
  const RescuerHomeScreen({super.key});

  @override
  State<RescuerHomeScreen> createState() => _RescuerHomeScreenState();
}

class _RescuerHomeScreenState extends State<RescuerHomeScreen> {
  final MapController _mapController = MapController();
  Stream<List<VictimBeacon>>? _stream;
  List<VictimBeacon> _beacons = const [];
  VictimBeacon? _selected;
  // Kurtarılmış olarak işaretlenen beacon ID'leri — listeden ve haritadan düşürülür.
  final Set<String> _rescuedIds = <String>{};

  LatLng _userLocation = BeaconScannerService.demoCenter;
  bool _gpsReady = false;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _stream = BeaconScannerService.instance.scan();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      // İlk konumu hızlı al
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _gpsReady = true;
        });
        _mapController.move(_userLocation, 16);
      } catch (_) {}

      // Stream canlı güncelle
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((p) {
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(p.latitude, p.longitude);
          _gpsReady = true;
        });
      });
    } catch (_) {}
  }

  double _distanceTo(VictimBeacon b) {
    const d = Distance();
    return d.as(LengthUnit.Meter, _userLocation, b.location);
  }

  String _humanDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _humanDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} sa ${d.inMinutes % 60} dk';
    if (d.inMinutes >= 1) return '${d.inMinutes} dk';
    return '${d.inSeconds} sn';
  }

  Color _urgencyColor(VictimBeacon b) {
    if (b.batteryPercent < 15) return AppColors.critical;
    if (b.batteryPercent < 35) return AppColors.amber;
    return AppColors.primary;
  }

  void _focus(VictimBeacon b) {
    setState(() => _selected = b);
    _mapController.move(b.location, 17);
  }

  void _markRescued(VictimBeacon b) {
    setState(() {
      _rescuedIds.add(b.anonymousId);
      if (_selected?.anonymousId == b.anonymousId) {
        _selected = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mağdur ${b.anonymousId} kurtarıldı olarak işaretlendi.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<VictimBeacon>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) _beacons = snapshot.data!;
            final sorted = _beacons
                .where((b) => !_rescuedIds.contains(b.anonymousId))
                .toList()
              ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));

            return Stack(
              children: [
                _buildMap(sorted),
                Positioned(
                  left: 16,
                  top: 12,
                  right: 16,
                  child: _TopBar(
                    activeCount: sorted.length,
                    gpsReady: _gpsReady,
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go('/rescuer'),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 84,
                  child: _FloatingActionTile(
                    icon: Icons.medical_information_rounded,
                    label: 'Triaj',
                    onTap: () => context.push('/rescuer/triage'),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _BottomSheet(
                        selected: _selected,
                        beacons: sorted,
                        distanceTo: (b) => _humanDistance(_distanceTo(b)),
                        durationOf: (b) => _humanDuration(b.broadcastDuration),
                        onSelect: _focus,
                        onClose: () => setState(() => _selected = null),
                        onMarkRescued: _markRescued,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(List<VictimBeacon> beacons) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation,
        initialZoom: 16,
        minZoom: 4,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.appjam.yaninda',
          tileProvider: CachedTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation,
              width: 36,
              height: 36,
              child: const _RescuerSelfMarker(),
            ),
            ...beacons.map(
              (b) => Marker(
                point: b.location,
                width: 56,
                height: 56,
                child: GestureDetector(
                  onTap: () => _focus(b),
                  child: _BeaconMarker(
                    beacon: b,
                    color: _urgencyColor(b),
                    highlighted: _selected?.anonymousId == b.anonymousId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────── top bar ───────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.activeCount,
    required this.gpsReady,
    required this.onBack,
  });

  final int activeCount;
  final bool gpsReady;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const _PulsingDot(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tarama aktif',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16,
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            gpsReady
                                ? Icons.gps_fixed_rounded
                                : Icons.gps_not_fixed_rounded,
                            size: 11,
                            color: gpsReady
                                ? AppColors.primary
                                : AppColors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$activeCount sinyal · ${gpsReady ? "GPS aktif" : "GPS aranıyor"}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'KURTARICI',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 10,
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

class _FloatingActionTile extends StatelessWidget {
  const _FloatingActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.critical, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withValues(alpha: 0.45 * (1 - _c.value)),
                ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────── markers ───────────────────────────────────

class _RescuerSelfMarker extends StatelessWidget {
  const _RescuerSelfMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.rescuer,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: AppColors.textOnPrimary,
        size: 18,
      ),
    );
  }
}

class _BeaconMarker extends StatefulWidget {
  const _BeaconMarker({
    required this.beacon,
    required this.color,
    required this.highlighted,
  });

  final VictimBeacon beacon;
  final Color color;
  final bool highlighted;

  @override
  State<_BeaconMarker> createState() => _BeaconMarkerState();
}

class _BeaconMarkerState extends State<_BeaconMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
            // Outer pulse
            Transform.scale(
              scale: 0.6 + _c.value * 0.9,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color
                      .withValues(alpha: 0.35 * (1 - _c.value)),
                ),
              ),
            ),
            // Marker pin
            AnimatedScale(
              scale: widget.highlighted ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.front_hand_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────── bottom sheet ──────────────────────────────

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.selected,
    required this.beacons,
    required this.distanceTo,
    required this.durationOf,
    required this.onSelect,
    required this.onClose,
    required this.onMarkRescued,
  });

  final VictimBeacon? selected;
  final List<VictimBeacon> beacons;
  final String Function(VictimBeacon) distanceTo;
  final String Function(VictimBeacon) durationOf;
  final void Function(VictimBeacon) onSelect;
  final VoidCallback onClose;
  final void Function(VictimBeacon) onMarkRescued;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: selected == null
              ? _ListView(
                  beacons: beacons,
                  distanceTo: distanceTo,
                  onSelect: onSelect,
                )
              : _DetailView(
                  beacon: selected!,
                  distance: distanceTo(selected!),
                  duration: durationOf(selected!),
                  onClose: onClose,
                  onMarkRescued: () => onMarkRescued(selected!),
                ),
        ),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.beacons,
    required this.distanceTo,
    required this.onSelect,
  });

  final List<VictimBeacon> beacons;
  final String Function(VictimBeacon) distanceTo;
  final void Function(VictimBeacon) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 28, height: 2, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'TESPİT EDİLEN MAĞDURLAR',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${beacons.length}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              itemCount: beacons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = beacons[i];
                return _BeaconListTile(
                  beacon: b,
                  distance: distanceTo(b),
                  onTap: () => onSelect(b),
                )
                    .animate(delay: (i * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .moveX(begin: -10, end: 0, duration: 300.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BeaconListTile extends StatelessWidget {
  const _BeaconListTile({
    required this.beacon,
    required this.distance,
    required this.onTap,
  });

  final VictimBeacon beacon;
  final String distance;
  final VoidCallback onTap;

  Color get _urgencyColor {
    if (beacon.batteryPercent < 15) return AppColors.critical;
    if (beacon.batteryPercent < 35) return AppColors.amber;
    return AppColors.primary;
  }

  IconData get _batteryIcon {
    if (beacon.batteryPercent < 20) return Icons.battery_alert_rounded;
    if (beacon.batteryPercent < 50) return Icons.battery_3_bar_rounded;
    return Icons.battery_full_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _urgencyColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _urgencyColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _urgencyColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.front_hand_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mağdur · ${beacon.anonymousId}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(_batteryIcon, size: 12, color: _urgencyColor),
                      const SizedBox(width: 3),
                      Text(
                        '%${beacon.batteryPercent}',
                        style: AppTypography.labelSmall.copyWith(
                          color: _urgencyColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (beacon.bloodType != null) ...[
                        const Icon(
                          Icons.bloodtype_rounded,
                          size: 12,
                          color: AppColors.critical,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          beacon.bloodType!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.critical,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distance,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _urgencyColor,
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

// ──────────────────────────────── detail view ───────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.beacon,
    required this.distance,
    required this.duration,
    required this.onClose,
    required this.onMarkRescued,
  });

  final VictimBeacon beacon;
  final String distance;
  final String duration;
  final VoidCallback onClose;
  final VoidCallback onMarkRescued;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = beacon.batteryPercent < 15
        ? AppColors.critical
        : beacon.batteryPercent < 35
            ? AppColors.amber
            : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.front_hand_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mağdur · ${beacon.anonymousId}',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'BLE Beacon · RSSI ${beacon.rssi} dBm',
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.straighten_rounded,
                label: distance,
                color: AppColors.primary,
              ),
              _Chip(
                icon: Icons.timer_rounded,
                label: duration,
                color: AppColors.teal,
              ),
              _Chip(
                icon: beacon.batteryPercent < 20
                    ? Icons.battery_alert_rounded
                    : Icons.battery_3_bar_rounded,
                label: '%${beacon.batteryPercent} pil',
                color: urgencyColor,
              ),
              if (beacon.bloodType != null)
                _Chip(
                  icon: Icons.bloodtype_rounded,
                  label: beacon.bloodType!,
                  color: AppColors.critical,
                ),
              ...beacon.medicalFlags.map(
                (f) => _Chip(
                  icon: Icons.medical_information_rounded,
                  label: f,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: 'Yön Bul',
                  icon: Icons.navigation_rounded,
                  onTap: () {
                    // TODO: Yon bulma ekrani (RSSI bazli sicak-soguk).
                  },
                ),
              ),
              const SizedBox(width: 10),
              _SecondaryButton(
                label: 'Kurtarıldı',
                icon: Icons.check_circle_rounded,
                onTap: onMarkRescued,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
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
          const SizedBox(width: 5),
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primarySoft, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textOnPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
