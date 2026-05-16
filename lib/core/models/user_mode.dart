enum UserMode {
  victim,
  rescuer;

  String get displayName => switch (this) {
        UserMode.victim => 'Depremzede',
        UserMode.rescuer => 'Destek ve Kurtarma',
      };

  String get description => switch (this) {
        UserMode.victim => 'Yardıma ihtiyacım var',
        UserMode.rescuer => 'Yardım etmek istiyorum',
      };
}
