class LiveBeacon {
  final String deviceId;
  final String anonymousId;
  final double latitude;
  final double longitude;
  final int batteryPercent;
  final String? bloodType;
  final List<String> medicalFlags;
  final DateTime? broadcastStartedAt;
  final DateTime? lastSeenAt;

  LiveBeacon({
    required this.deviceId,
    required this.anonymousId,
    required this.latitude,
    required this.longitude,
    this.batteryPercent = 100,
    this.bloodType,
    this.medicalFlags = const [],
    this.broadcastStartedAt,
    this.lastSeenAt,
  });

  // Supabase'den (JSON) gelen veriyi Dart formatına çevirir
  factory LiveBeacon.fromJson(Map<String, dynamic> json) {
    return LiveBeacon(
      deviceId: json['device_id'],
      anonymousId: json['anonymous_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      batteryPercent: json['battery_percent'] ?? 100,
      bloodType: json['blood_type'],
      // PostgreSQL'deki text[] array'ini Dart listesine çeviriyoruz
      medicalFlags: List<String>.from(json['medical_flags'] ?? []),
      broadcastStartedAt: json['broadcast_started_at'] != null
          ? DateTime.parse(json['broadcast_started_at'])
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }

  // Dart nesnesini Supabase'in (SQL) anlayacağı formata çevirir
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'anonymous_id': anonymousId,
      'latitude': latitude,
      'longitude': longitude,
      'battery_percent': batteryPercent,
      if (bloodType != null) 'blood_type': bloodType,
      'medical_flags': medicalFlags,
      // Zaman damgalarını Supabase default now() ile kendi atayacak
    };
  }
}
