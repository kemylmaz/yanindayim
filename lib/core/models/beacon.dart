import 'package:hive/hive.dart';

part 'beacon.g.dart';

@HiveType(typeId: 4)
class Beacon {
  @HiveField(0)
  String anonymousId;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  int batteryPercent;

  @HiveField(4)
  String bloodType;

  @HiveField(5)
  List<String> medicalFlags;

  @HiveField(6)
  DateTime broadcastStarted;

  @HiveField(7)
  int? rssi; // Sadece kurtarıcı tarafı

  @HiveField(8)
  DateTime? lastSeen;

  Beacon({
    required this.anonymousId,
    required this.latitude,
    required this.longitude,
    required this.batteryPercent,
    required this.bloodType,
    required this.medicalFlags,
    required this.broadcastStarted,
    this.rssi,
    this.lastSeen,
  });
}
