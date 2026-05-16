enum UserMode {
  victim,
  rescuer;

  String get displayName => switch (this) {
        UserMode.victim => 'Mağdur',
        UserMode.rescuer => 'Kurtarıcı',
      };

  String get description => switch (this) {
        UserMode.victim =>
          'Deprem anında ve sonrasında size yardım eder. SOS, beacon yayını, AI rehber ve PFA modu.',
        UserMode.rescuer =>
          'Yaralılara ulaşmak için tarama yapar. Mağdurları haritada görürsünüz.',
      };
}
