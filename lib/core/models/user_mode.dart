import 'package:hive/hive.dart';

part 'user_mode.g.dart';

@HiveType(typeId: 1)
enum UserMode {
  @HiveField(0)
  victim,
  @HiveField(1)
  rescuer;

  String get displayName => switch (this) {
        UserMode.victim => 'Depremzede',
        UserMode.rescuer => 'Destek Birimi',
      };

  String get description => switch (this) {
        UserMode.victim => 'Yardıma ihtiyacım var',
        UserMode.rescuer => 'Yardım etmek istiyorum',
      };
}
