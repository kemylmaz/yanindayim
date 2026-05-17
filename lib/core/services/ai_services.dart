// Bu servis, yerel Gemma modelini yönetir ve kullanıcının sorularını
// bilgi bankasından (RAG) gelen bağlam verileriyle birleştirerek cevap üretir.

//flutterGemma.getActiveModel üzerinden InferenceModel ve InferenceChat
//nesnelerini yakalayıp, GPU tercihini belirterek
// addQueryChunk ve generateChatResponse akışını kurduk

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'knowledge_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final knowledgeService = ref.watch(knowledgeServiceProvider);
  return AIService(knowledgeService);
});

class AIService {
  final KnowledgeService _knowledgeService;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _gemmaTried = false;

  AIService(this._knowledgeService);

  bool get isGemmaReady => _chat != null;

  /// Gemma modelini bir kez başlatmayı dener. Cihazda model yüklü değilse
  /// sessizce başarısız olur — bu durumda bilgi bankası fallback'i kullanılır.
  Future<void> initModel() async {
    if (_gemmaTried) return;
    _gemmaTried = true;
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );
      _chat = await _model!.createChat();
      debugPrint('✅ Yerel Gemma modeli hazır.');
    } catch (e) {
      debugPrint('ℹ️ Gemma modeli yok, bilgi bankası fallback kullanılacak: $e');
      _model = null;
      _chat = null;
    }
  }

  Future<String> answerQuestion(String userQuery) async {
    // 1) Acil durum radarı — Gemma olsun olmasın garantili spesifik yanıt.
    final scenarioAnswer = _matchScenario(userQuery);
    if (scenarioAnswer != null) return scenarioAnswer;

    // 2) Gemma + RAG yolu (Gemma yüklüyse).
    if (!_gemmaTried) await initModel();

    final chunk = _knowledgeService.bestChunk(userQuery);

    if (isGemmaReady) {
      final answer = await _askGemma(userQuery, chunk?['text']?.toString());
      if (answer != null && answer.trim().isNotEmpty) return answer;
    }

    // 3) Knowledge base fallback (Türkçeleştirme + kısaltma).
    return _knowledgeFallback(userQuery, chunk);
  }

  /// 14 senaryolu acil durum radarı. Soruyu kök kelime taramasıyla yakalar,
  /// kullanıcıya panik yaptırmayan, eyleme yönelik kısa yanıt verir.
  /// Gemma çökse bile, knowledge base bulamasa bile çalışır.
  String? _matchScenario(String query) {
    final q = query.toLowerCase();
    bool has(List<String> keys) => keys.any(q.contains);

    // 1. ENKAZ / SIKIŞMA — psikolojik ilk yardım + ses sinyali
    if (has(['enkaz', 'göçük', 'gocuk', 'yıkıntı', 'yikinti', 'sıkış',
            'sikis', 'altında kaldım', 'altinda kaldim', 'üzerime', 'uzerime'])) {
      return 'Sakin ol, yalnız değilsin. Derin ve yavaş nefes al, enerjini koru.\n\n'
          'Bağırmak yerine sert bir cisme (taş, demir, boru) her 3 dakikada bir '
          '3 kez ritmik vurarak sesini duyur. Bu hem enerji harcatmaz hem '
          'kurtarıcılar tarafından daha kolay duyulur.\n\n'
          'Ana ekrandaki S.O.S butonuna bastıysan beacon sinyalin yayında. '
          'Konumun yakındaki kurtarıcı uygulamalarına iletildi.';
    }

    // 2. YAKINLARINA ULAŞMA
    if (has(['çocuğum', 'cocugum', 'ailem', 'eşim', 'esim', 'annem', 'babam',
            'kardeşim', 'kardesim', 'yakınım', 'yakinim', 'nerede',
            'ulaşamıyorum', 'ulasamiyorum', 'haber alamıyorum', 'haber alamiyorum'])) {
      return 'Anlıyorum, çok zor bir durum. Sahte umut vermeyeceğim ama '
          'AFAD, UMKE ve gönüllü ekipler şu anda sahada çalışıyor.\n\n'
          'Yakınının durumunu öğrenmek için:\n'
          '• 112\'yi ara (afet hattı)\n'
          '• İnternetin varsa e-Devlet → "Afetzede Sorgulama"\n'
          '• AFAD Kayıp/Bulunan listesi (afad.gov.tr)\n\n'
          'Şimdilik güvenli bir alanda kal ve telefon pilini koru. '
          'Haber gelene kadar SOS\'u kapatmadan beklemen daha güvenli.';
    }

    // 3. TOPLANMA ALANI / HARİTA
    if (has(['toplanma', 'toplanma alanı', 'harita', 'buluşma', 'bulusma',
            'nereye gideyim', 'güvenli yer', 'guvenli yer'])) {
      return 'Çevrimdışı haritamda Balıkesir bölgesindeki tüm AFAD onaylı '
          'toplanma alanları yüklü.\n\n'
          'Ana ekranın altındaki "Toplanma" butonuna bas — sana en yakın '
          '3 alan otomatik listelenir. Bir noktaya dokunduğunda yön çizgisi '
          'görünür.\n\n'
          'Toplanma alanına giderken: ana yollardan uzak dur, yıkılabilir '
          'duvar/balkonlardan kaçın, ayakkabını giy.';
    }

    // 4. KANAMA / İLK YARDIM
    if (has(['kanama', 'kan akıyor', 'kan akiyor', 'kanıyor', 'kaniyor',
            'yara', 'yaralı', 'yarali', 'ilk yardım', 'ilk yardim'])) {
      return 'Kanama kontrolü 3 adım:\n\n'
          '1. **Bas:** Temiz bez/kıyafetle yara üstüne sıkıca bas, en az '
          '10 dakika kaldırma.\n\n'
          '2. **Yenileme yapma:** Kan emen bezi çıkarma; üstüne ikinci bir '
          'bez ekle. Bezi kaldırmak pıhtıyı bozar.\n\n'
          '3. **Yukarı kaldır:** Yaralı bölge varsa kalp seviyesinin üstünde '
          'tut (kol/bacak yarası için).\n\n'
          'Atardamar kanaması (fışkıran kan) varsa: 112\'yi hemen ara, '
          'turnike son çare — kullanım saatini yaz.';
    }

    // 5. PANİK ATAK / KORKU
    if (has(['panik', 'korkuyorum', 'nefes alamıyorum', 'nefes alamiyorum',
            'kalbim hızlı', 'kalbim hizli', 'çıldıracağım', 'cildiracagim',
            'titriyorum', 'sakinleş', 'sakinles', 'sakinleştir', 'sakinlestir'])) {
      return 'Panik atak yaşıyor olabilirsin. Hayati tehlikesi yok, 5-20 '
          'dakikada geçer. Şu nefes egzersizini birlikte yapalım:\n\n'
          '🌬️ **4-7-8 tekniği**\n'
          '• 4 saniye burnundan yavaşça nefes al\n'
          '• 7 saniye nefesi tut\n'
          '• 8 saniye ağzından yavaşça ver\n'
          '• 4 defa tekrarla\n\n'
          'Bir cisim tut (anahtar, su şişesi) — gerçekliğe geri döndürür. '
          'Aklından geçenlere odaklanma, sadece nefesini say.';
    }

    // 6. ARTÇI SARSINTI / TEKRAR DEPREM
    if (has(['artçı', 'artci', 'tekrar deprem', 'yine sallandı', 'yine sallandi',
            'tekrar sallandı', 'tekrar sallandi', 'devamı gelir mi', 'devami gelir mi'])) {
      return 'Artçı sarsıntılar ana depremden sonra günler-haftalar boyunca '
          'sürebilir. Genelde ana depremden hafif olur ama yapı zaten '
          'hasarlıysa yıkım yapabilir.\n\n'
          '• Hasarlı binalara **kesinlikle girme**, eşyanı kurtarmaya çalışma\n'
          '• Açık alan / toplanma alanında kal\n'
          '• Sırt çantanı yanında bulundur (su, fener, kimlik)\n'
          '• Yeni bir sarsıntıda: çök, sığın (sağlam masa altı), tutun\n\n'
          'AFAD ve Kandilli artçı uyarılarını takip et.';
    }

    // 7. SU BULMA / İÇME SUYU
    if (has(['su', 'içecek su', 'icecek su', 'içme suyu', 'icme suyu',
            'susadım', 'susadim', 'içme', 'icme'])) {
      return 'Su, hayatta kalmada gıdadan daha kritik. Günde kişi başı '
          'en az 1 litre.\n\n'
          '🚰 **Acil su kaynakları:**\n'
          '• Sıcak su tankı (binada güvenliyse) — temiz, içilebilir\n'
          '• Tuvalet rezervuarı (taze su tankı, kimyasal eklenmemişse)\n'
          '• Kapalı şişeler, konserve sıvıları\n'
          '• Buzdolabındaki sebze-meyve\n\n'
          '⚠️ **İçme:** Şüpheli su için 1 dakika kaynat, yoksa 1 litreye '
          '2 damla çamaşır suyu (kokusuz), 30 dk bekle.\n'
          '❌ **Kullanma:** Kalorifer, havuz, akvaryum, çamaşır makinesi.';
    }

    // 8. PİL / TELEFON TASARRUFU
    if (has(['pil', 'şarj', 'sarj', 'batarya', 'telefon kapanıyor',
            'telefon kapaniyor', 'enerji tasarruf'])) {
      return 'Telefonun enkazda hayat kurtarır — pili akıllı kullan.\n\n'
          '🔋 **Hemen yap:**\n'
          '• Uçak modu aç (şebeke aramaktan vazgeç, pil yer)\n'
          '• Parlaklığı minimuma çek\n'
          '• Bluetooth/Wi-Fi/GPS kapat (BLE Beacon hariç)\n'
          '• Bildirimleri sustur, titreşimi kapat\n'
          '• Kamera flaşını kullanma\n\n'
          'Yanındayım uygulaması zaten enerji tasarruflu modda çalışır. '
          '%50 pille modern telefon enkazda 12-18 saat dayanabilir.\n\n'
          'SMS aramadan çok daha az pil harcar — yakınlarına SMS at, arama.';
    }

    // 9. YANGIN / DUMAN
    if (has(['yangın', 'yangin', 'duman', 'alev', 'yanıyor', 'yaniyor',
            'is kokusu', 'gaz kokusu', 'doğalgaz', 'dogalgaz'])) {
      return 'Yangın/duman varsa hızlı ve sakin hareket et.\n\n'
          '🔥 **Anında:**\n'
          '• Doğalgaz vanasını kapat (mutfakta/dışarıda)\n'
          '• Elektrik şalterini indir\n'
          '• Çakmak/kibrit yakma, telefon çağrısı yapma '
          '(kıvılcım gaz patlaması yapar)\n\n'
          '🌬️ **Dumandan korunma:**\n'
          '• Yere yat, sürünerek ilerle (duman yukarıda toplanır)\n'
          '• Ağzına ıslak bez koy\n'
          '• Kapı tokmağı sıcaksa açma, başka çıkış bul\n\n'
          'Yangın küçükse: söndürücü, battaniye veya su. Büyükse: derhal '
          'çık, 112\'yi ara.';
    }

    // 10. GIDA / AÇLIK
    if (has(['yemek', 'gıda', 'gida', 'açım', 'acim', 'aç kaldım', 'ac kaldim',
            'erzak', 'beslen'])) {
      return 'Bir insan susuzluğa 3 gün, açlığa 3 hafta dayanır. Önceliğin su.\n\n'
          '🍞 **Acil erzak:**\n'
          '• Kuru: bisküvi, kraker, kuruyemiş, kuru meyve\n'
          '• Konserve: balık, ton, fasulye, sebze (açacak şart)\n'
          '• Energy bar, çikolata (pickup için iyi)\n'
          '• Çocuk maması (varsa)\n\n'
          '⚠️ **Yeme:** Soğuk konserveyi bile yiyebilirsin. Buzdolabında '
          'açılmış et/süt 4 saat sonra yeme.\n'
          '✅ **Rasyon:** Kişi başı günde ~1500 kalori — 3-7 gün için planla.';
    }

    // 11. SOĞUK / ISINMA
    if (has(['soğuk', 'soguk', 'üşüyorum', 'usuyorum', 'ısınma', 'isinma',
            'donuyorum', 'titriyor', 'üşüme', 'usume'])) {
      return 'Hipotermi (vücut ısısının düşmesi) sessizce öldürür. Önle.\n\n'
          '🧥 **Vücut ısısı koruma:**\n'
          '• Katmanlı giyin (3 ince > 1 kalın)\n'
          '• Baş + boyun + el + ayak öncelikli (en çok ısı kaybı buradan)\n'
          '• Yere oturma — battaniye/karton sere, izole et\n'
          '• Diğer kişilerle yan yana, ısıyı paylaş\n\n'
          '🔥 **Isınma:**\n'
          '• Sıcak şeker/tatlı yer (vücut hızlı yakar)\n'
          '• Hafif egzersiz (kollarını çırpma, kollarını ovuştur)\n'
          '❌ **Alkol içme** — damarları gevşetir, daha çok ısı kaybedersin.';
    }

    // 12. ÇIKAMIYORUM / EVDE MAHSUR
    if (has(['çıkamıyorum', 'cikamiyorum', 'kapı açılmıyor', 'kapi acilmiyor',
            'asansör', 'asansor', 'merdiven yok', 'mahsur'])) {
      return 'Çıkış kapalıysa enerjini koru, akıllı seçenekleri dene.\n\n'
          '🚪 **Önce:**\n'
          '• Tüm pencerelerden bak, alt kata sesle sor\n'
          '• Komşulara duvara vur (3 kez ritmik)\n'
          '• Telefon ile yardım çağır\n\n'
          '🪟 **Pencereler:**\n'
          '• Çarşaf bağlayarak iniş çok riskli — son çare\n'
          '• İmdat penceresi/balkon varsa kullan, atlama\n\n'
          '⚠️ **Asansör:** Asla kullanma — elektrik kesilirse mahsur kalırsın.\n\n'
          'Kapı pencere yoksa: SOS bas, sesini düzenli aralıklarla duyur, bekle.';
    }

    // 13. ŞOK / BAYGINLIK
    if (has(['şok', 'sok', 'bayıldı', 'bayildi', 'bilinci yok', 'tepkisiz',
            'kalp durdu', 'baygin', 'baygın'])) {
      return 'Şok veya baygınlık → hayati önemli.\n\n'
          '🚨 **Hemen:**\n'
          '1. Omzuna vur, seslen — tepki yoksa 112\'yi ara\n'
          '2. Nefes alıyor mu? Göğsü kalkıyor mu? Bak.\n'
          '3. Nefes yok → **30 göğüs masajı + 2 nefes** sırayla, yardım gelene kadar\n'
          '4. Nefes var ama bilinçsiz → **yan yatış pozisyonu** (boğulmayı engeller)\n\n'
          '🩹 **Şok belirtileri:** soğuk-nemli ten, hızlı zayıf nabız, sığ nefes, '
          'huzursuzluk. Yatır, ayaklarını 30cm yükselt, üzerini ört, sıvı verme.';
    }

    // 14. BÖLGEDE GÜVENLİK / ÇIKABİLİR MİYİM
    if (has(['bina sağlam', 'bina saglam', 'çıkabilir miyim', 'cikabilir miyim',
            'güvenli mi', 'guvenli mi', 'hasar var mı', 'hasar var mi',
            'binam', 'evim', 'çıksam mı', 'ciksam mi'])) {
      return 'Sarsıntıdan hemen sonra bina sağlamlığı kontrolü:\n\n'
          '⚠️ **Çıkış işareti (TEHLİKE):**\n'
          '• Görünür çatlak (kolon, kiriş, taşıyıcı duvar)\n'
          '• Eğik duvar/zemin\n'
          '• Asansör boşluğunda çatlak/aralık\n'
          '• Düşmüş tavan, sallanan beton\n'
          '• Doğalgaz/yanık plastik kokusu\n\n'
          '✅ **Çıkış yolu:**\n'
          '• Ayakkabını giy (cam parçaları)\n'
          '• Ana yollardan değil, açık alanlardan ilerle\n'
          '• Toplanma alanına git (Yanındayım haritasından bak)\n\n'
          'Şüphe varsa: girme. Hasar tespiti AFAD/belediye uzmanı işidir.';
    }

    return null; // Senaryo eşleşmedi → normal RAG yoluna geç
  }

  Future<String?> _askGemma(String userQuery, String? context) async {
    try {
      final prompt = context != null && context.isNotEmpty
          ? '''
Sen 'Yanındayım' isimli çevrimdışı deprem ve acil durum asistanısın.
Yalnızca aşağıdaki güvenilir bilgileri kullanarak kısa, net ve sakinleştirici bir cevap ver.
Asla bu bilgilerin dışına çıkma ve hayali bilgi uydurma.

[GÜVENİLİR BİLGİ]:
$context

[KULLANICI SORUSU]:
$userQuery
'''
          : '''
Sen 'Yanındayım' isimli acil durum asistanısın.
Kullanıcıya deprem, ilk yardım veya hayatta kalma konularında kısa, net ve panik yaptırmayacak bir cevap ver.

[KULLANICI SORUSU]:
$userQuery
''';

      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final result = await _chat!.generateChatResponse();
      final text = (result as dynamic).text as String? ??
          (result as dynamic).token as String? ??
          result.toString();
      return text;
    } catch (e) {
      debugPrint('⚠️ Gemma yanıt üretemedi, fallback kullanılıyor: $e');
      return null;
    }
  }

  /// Bilgi bankasından gelen chunk'ı kullanıcı dostu kısa bir yanıta dönüştürür.
  /// Hackathon demosu için Gemma indirilmemiş olsa da kullanışlı cevaplar verir.
  String _knowledgeFallback(String userQuery, Map<String, dynamic>? chunk) {
    if (chunk == null) {
      return 'Bu konuda elimde güvenilir bilgi yok. '
          'Acil bir durumdaysan 112\'yi ara veya ana ekrandan SOS butonuna bas.';
    }

    final title = _turkify(chunk['title']?.toString().trim() ?? '');
    final rawText = chunk['text']?.toString().trim() ?? '';
    final shortened = _shorten(_turkify(rawText), maxChars: 700);

    if (title.isNotEmpty) {
      return '$title\n\n$shortened';
    }
    return shortened;
  }

  String _shorten(String text, {required int maxChars}) {
    if (text.length <= maxChars) return text;
    final slice = text.substring(0, maxChars);
    final lastStop = slice.lastIndexOf(RegExp(r'[\.\!\?]'));
    if (lastStop > maxChars ~/ 2) {
      return '${slice.substring(0, lastStop + 1)}…';
    }
    return '$slice…';
  }

  /// Knowledge base ASCII (Türkçe karaktersiz) yazılmış. Burada yaygın deprem
  /// terimlerini gerçek Türkçe karakterlerine dönüştürür. Tüm kelimeleri
  /// sözlüğe sığdırmaya çalışmadan, demoda dikkat çekenleri kapsar.
  String _turkify(String text) {
    if (text.isEmpty) return text;
    var out = text;
    for (final entry in _trDict.entries) {
      // Kelime bütünü olarak değiştir (word boundaries).
      out = out.replaceAllMapped(
        RegExp(r'\b' + entry.key + r'\b', caseSensitive: false),
        (m) => _preserveCase(m.group(0)!, entry.value),
      );
    }
    return out;
  }

  /// Bulunan kelimenin büyük/küçük harf desenini korur ("Sehir" → "Şehir").
  String _preserveCase(String matched, String replacement) {
    if (matched.isEmpty) return replacement;
    if (matched == matched.toUpperCase()) return replacement.toUpperCase();
    if (matched[0] == matched[0].toUpperCase()) {
      return replacement[0].toUpperCase() + replacement.substring(1);
    }
    return replacement;
  }

  /// Yaygın ASCII → Türkçe dönüşüm sözlüğü.
  static const Map<String, String> _trDict = {
    // genel
    'icin': 'için', 'cunku': 'çünkü', 'cunkii': 'çünkü', 'cok': 'çok',
    'cogu': 'çoğu', 'ozellikle': 'özellikle', 'bircok': 'birçok',
    'cesitli': 'çeşitli', 'cevap': 'cevap', 'cesit': 'çeşit',
    'icine': 'içine', 'icinde': 'içinde', 'iceren': 'içeren',
    'icerik': 'içerik', 'ileride': 'ileride', 'oncelikli': 'öncelikli',
    'onerilen': 'önerilen', 'onerilir': 'önerilir', 'onemli': 'önemli',
    'once': 'önce', 'onunde': 'önünde', 'siyle': 'şiyle', 'sasirma': 'şaşırma',
    'sasirtici': 'şaşırtıcı',
    // deprem terimleri
    'deprem': 'deprem', 'oncesi': 'öncesi', 'sirasinda': 'sırasında',
    'sonrasi': 'sonrası', 'sonra': 'sonra', 'panik': 'panik',
    'yikinti': 'yıkıntı', 'enkaz': 'enkaz', 'sarsinti': 'sarsıntı',
    'hareketi': 'hareketi', 'kacis': 'kaçış', 'cikis': 'çıkış',
    'cikar': 'çıkar', 'cikin': 'çıkın', 'cikti': 'çıktı', 'cikabilir': 'çıkabilir',
    'cocuk': 'çocuk', 'cocuklar': 'çocuklar', 'cocugunuz': 'çocuğunuz',
    'aile': 'aile', 'yakininiz': 'yakınınız', 'yakini': 'yakını',
    'guvenli': 'güvenli', 'guvenligi': 'güvenliği', 'guvenlik': 'güvenlik',
    'tehlikeli': 'tehlikeli', 'tehlikede': 'tehlikede', 'tehlike': 'tehlike',
    // yiyecek-içecek
    'su': 'su', 'gida': 'gıda', 'yemek': 'yemek', 'icmek': 'içmek',
    'icme': 'içme', 'bardak': 'bardak', 'sise': 'şişe',
    // vücut
    'kalp': 'kalp', 'nefes': 'nefes', 'soluk': 'soluk', 'akciger': 'akciğer',
    'kan': 'kan', 'kanama': 'kanama', 'yara': 'yara', 'yarali': 'yaralı',
    'agri': 'ağrı', 'agir': 'ağır', 'soguk': 'soğuk', 'sicaklik': 'sıcaklık',
    'sicak': 'sıcak', 'kalp atisi': 'kalp atışı',
    // konum-yön
    'asagi': 'aşağı', 'asagisinda': 'aşağısında', 'asagiya': 'aşağıya',
    'asagida': 'aşağıda', 'asagidan': 'aşağıdan',
    'yukari': 'yukarı', 'yukariya': 'yukarıya', 'yukarida': 'yukarıda',
    'yan': 'yan', 'ust': 'üst', 'usten': 'üsten', 'ustte': 'üstte',
    'altinda': 'altında', 'altina': 'altına', 'altta': 'altta',
    'ic': 'iç', 'ice': 'içe', 'icinden': 'içinden',
    'dis': 'dış', 'disinda': 'dışında', 'disari': 'dışarı', 'disariya': 'dışarıya',
    'arasinda': 'arasında', 'aralarinda': 'aralarında',
    // sıfatlar
    'agirlik': 'ağırlık', 'agirligi': 'ağırlığı', 'agirligindan': 'ağırlığından',
    'buyuk': 'büyük', 'buyumesi': 'büyümesi', 'kucuk': 'küçük',
    'genis': 'geniş', 'genisleyerek': 'genişleyerek', 'gunluk': 'günlük',
    'gunler': 'günler', 'gun': 'gün', 'haftalar': 'haftalar',
    'yili': 'yılı', 'yil': 'yıl', 'yilbasi': 'yılbaşı',
    'duzenli': 'düzenli', 'duzgun': 'düzgün',
    // fiiller
    'yapin': 'yapın', 'yapinca': 'yapınca', 'yapamiyorsaniz': 'yapamıyorsanız',
    'bekleyin': 'bekleyin', 'duraklayin': 'duraklayın', 'durdurun': 'durdurun',
    'bagirin': 'bağırın', 'cagirin': 'çağırın', 'arayin': 'arayın',
    'birakin': 'bırakın', 'birakmayin': 'bırakmayın',
    'kapatip': 'kapatıp', 'kapali': 'kapalı', 'kapatin': 'kapatın',
    'acin': 'açın', 'acin kapilari': 'açın kapıları', 'acabilir': 'açabilir',
    'sallayin': 'sallayın', 'sakin': 'sakin', 'sakinlik': 'sakinlik',
    // gibi
    'gore': 'göre', 'olabilir': 'olabilir', 'olusum': 'oluşum',
    'olusan': 'oluşan', 'olusturur': 'oluşturur',
    'kullanim': 'kullanım', 'kullanin': 'kullanın',
    'baska': 'başka', 'baslangic': 'başlangıç', 'baslar': 'başlar',
    'baslayin': 'başlayın', 'basiniz': 'başınız',
    'cesur': 'cesur', 'cesaret': 'cesaret',
    'ihtiyac': 'ihtiyaç', 'ihtiyaci': 'ihtiyacı', 'ihtiyaclar': 'ihtiyaçlar',
    'asagilara': 'aşağılara', 'yere': 'yere', 'yerden': 'yerden',
    'goz': 'göz', 'goren': 'gören', 'gorur': 'görür', 'gorulen': 'görülen',
    'gozetim': 'gözetim',
    // yardım terimleri
    'yardim': 'yardım', 'yardimci': 'yardımcı', 'yardimina': 'yardımına',
    'kurtarici': 'kurtarıcı', 'kurtarma': 'kurtarma', 'kurtulus': 'kurtuluş',
    'sehit': 'şehit', 'sehir': 'şehir',
    // sayılar
    'iki': 'iki', 'uc': 'üç', 'dort': 'dört', 'bes': 'beş',
    'alti': 'altı', 'yedi': 'yedi', 'sekiz': 'sekiz', 'dokuz': 'dokuz',
    'on': 'on', 'yuz': 'yüz', 'bin': 'bin',
    // misc
    'ozet': 'özet', 'ozetle': 'özetle', 'olcu': 'ölçü', 'olcun': 'ölçün',
    'olu': 'ölü', 'olum': 'ölüm', 'oldurucu': 'öldürücü',
    'omur': 'ömür', 'urun': 'ürün', 'ulke': 'ülke',
    'bolge': 'bölge', 'bolgesinde': 'bölgesinde',
    'tum': 'tüm', 'tumu': 'tümü', 'tek': 'tek',
    'serit': 'şerit', 'sehirde': 'şehirde',
  };
}
