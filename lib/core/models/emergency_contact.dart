import 'package:hive/hive.dart';

part 'emergency_contact.g.dart';

@HiveType(typeId: 2)
class EmergencyContact {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phoneE164; // +905XXXXXXXXX

  EmergencyContact({
    required this.name,
    required this.phoneE164,
  });
}
