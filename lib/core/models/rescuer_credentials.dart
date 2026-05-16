import 'package:hive/hive.dart';

part 'rescuer_credentials.g.dart';

@HiveType(typeId: 3)
class RescuerCredentials {
  @HiveField(0)
  String organization; // AKUT/AFAD/UMKE vb.

  @HiveField(1)
  String certificateNumber;

  @HiveField(2)
  String specialty; // arama-kurtarma, sağlık vb.

  RescuerCredentials({
    required this.organization,
    required this.certificateNumber,
    required this.specialty,
  });
}
