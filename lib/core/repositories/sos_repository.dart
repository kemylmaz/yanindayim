import 'package:flutter/foundation.dart'; // debugPrint için eklendi
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_beacon.dart';

class SosRepository {
  // 1. HATA ÇÖZÜMÜ: SupabaseClient tipi açıkça belirtildi
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. SOS SİNYALİ GÖNDERME (INSERT)
  Future<void> sendSosSignal(LiveBeacon signal) async {
    try {
      await _supabase.from('sos_signals').insert(signal.toJson());
      // 4. HATA ÇÖZÜMÜ: print yerine debugPrint kullanıldı
      debugPrint('🚨 BAŞARILI: SOS sinyali Supabase veritabanına ulaştı!');
    } catch (e) {
      debugPrint('❌ SOS Gönderme Hatası: $e');
      throw Exception('Sinyal gönderilemedi, çevrimdışı moda geçiliyor.');
    }
  }

  // 2. AKTİF SOS SİNYALLERİNİ ÇEKME (SELECT)
  Future<List<LiveBeacon>> getActiveSosSignals() async {
    try {
      // 2. HATA ÇÖZÜMÜ: Dönen verinin tipi baştan açıkça tanımlandı
      final List<Map<String, dynamic>> response = await _supabase
          .from('sos_signals')
          .select()
          .eq('is_active', true);

      // 3. HATA ÇÖZÜMÜ: Gereksiz (as List) kaldırıldı, doğrudan map'lendi
      return response.map((data) => LiveBeacon.fromJson(data)).toList();
    } catch (e) {
      debugPrint('❌ SOS Çekme Hatası: $e');
      return [];
    }
  }

  // 3. SOS SİNYALİNİ İPTAL ETME (UPDATE)
  Future<void> deactivateSosSignal(String signalId) async {
    try {
      await _supabase
          .from('sos_signals')
          .update({'is_active': false})
          .eq('id', signalId);
      debugPrint('✅ SOS sinyali başarıyla kapatıldı.');
    } catch (e) {
      debugPrint('❌ SOS Kapatma Hatası: $e');
    }
  }
}
