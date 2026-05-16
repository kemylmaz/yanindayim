import 'package:hive/hive.dart';
import 'user_mode.dart';
import 'emergency_contact.dart';
import 'rescuer_credentials.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String id;

  @HiveField(1)
  UserMode mode;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? bloodType;

  @HiveField(4)
  List<String> medicalFlags;

  @HiveField(5)
  List<EmergencyContact> emergencyContacts;

  @HiveField(6)
  RescuerCredentials? rescuerCreds;

  @HiveField(7)
  DateTime createdAt;

  User({
    required this.id,
    required this.mode,
    this.name,
    this.bloodType,
    required this.medicalFlags,
    required this.emergencyContacts,
    this.rescuerCreds,
    required this.createdAt,
  });
}
