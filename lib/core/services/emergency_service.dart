import 'package:url_launcher/url_launcher.dart';

/// SMS ve 112 acil çağrı için işletim sistemi intent'lerini açar.
/// Kullanıcı son onayı kendi verir — production app'in iyi UX'i ve yasal güvencesi.
class EmergencyService {
  EmergencyService._();
  static final instance = EmergencyService._();

  Future<bool> sendEmergencySms({
    required List<String> recipients,
    required String body,
  }) async {
    if (recipients.isEmpty) return false;
    final recipientList = recipients.join(',');
    final uri = Uri(
      scheme: 'sms',
      path: recipientList,
      queryParameters: {'body': body},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> callEmergency(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// SOS sırasında çağrılır — önce SMS, ardından 112 aramayı tetikler.
  Future<void> triggerSos({
    required List<String> emergencyContacts,
    required double? lastLat,
    required double? lastLng,
    required String userName,
  }) async {
    final locationLine = (lastLat != null && lastLng != null)
        ? '\nKonum: https://maps.google.com/?q=$lastLat,$lastLng'
        : '';
    final body = 'İmdat! $userName güvenli değil, acil yardıma ihtiyaç var.'
        '$locationLine\n— Yanındayım uygulamasından otomatik gönderildi.';

    if (emergencyContacts.isNotEmpty) {
      await sendEmergencySms(recipients: emergencyContacts, body: body);
    }
    await Future.delayed(const Duration(seconds: 1));
    await callEmergency('112');
  }
}
