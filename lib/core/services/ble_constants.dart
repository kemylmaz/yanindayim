/// İki cihaz arasında ortak BLE protokolü.
///
/// Mağdur cihazı [serviceUuid] üzerinden advertise eder, anonim ID'sini
/// local name'e, kan grubu kodu + pil yüzdesini manufacturer data'ya gömer.
/// Kurtarıcı cihazı aynı UUID ile scan yapar ve advertisement'i parse eder.
class BleConstants {
  BleConstants._();

  /// Uygulamaya özel servis UUID'si. flutter_blue_plus filter'a verilir.
  /// 128-bit (Base UUID variant). Custom for "Yanındayım".
  static const String serviceUuid = '00fed9-0000-1000-8000-00805f9b34fb';
  static const String serviceUuidFull =
      '0000fed9-0000-1000-8000-00805f9b34fb';

  /// Advertisement manufacturer ID — placeholder (Bluetooth SIG'de henüz
  /// ayrılmamış). 0xFFFF default test ID.
  static const int manufacturerId = 0xFFFF;

  /// Local name prefix — kurtarıcı bunu görerek yayının bizim app'imizden
  /// olduğunu anlar. "Y:emir" gibi.
  static const String localNamePrefix = 'Y:';

  /// Kan grubu → 1 byte kod tablosu (advertisement payload'da yer tasarrufu).
  static const Map<String, int> bloodTypeCodes = {
    '0+': 1, '0-': 2,
    'A+': 3, 'A-': 4,
    'B+': 5, 'B-': 6,
    'AB+': 7, 'AB-': 8,
  };

  static String? bloodTypeFromCode(int code) {
    for (final entry in bloodTypeCodes.entries) {
      if (entry.value == code) return entry.key;
    }
    return null;
  }
}
