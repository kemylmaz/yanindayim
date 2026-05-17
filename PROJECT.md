# YANINDA — Deprem Hayatta Kalma Uygulaması

> **Proje Dokümanı / Game Design Document benzeri kapsamlı tasarım belgesi**
> Bu dosya, projenin tüm tasarımını, kararlarını ve uygulanış planını içerir.
> Yapay zeka araçları (Claude, GPT, Gemini, Cursor vb.) bu dosyayı okuyarak projeye dahil olabilir, kod üretebilir, eksikleri tamamlayabilir.

---

## İÇİNDEKİLER

1. [Proje Özeti](#1-proje-özeti)
2. [Kısıtlamalar ve Bağlam](#2-kısıtlamalar-ve-bağlam)
3. [Hedef Kullanıcılar](#3-hedef-kullanıcılar)
4. [Felsefe ve Farklılaşma](#4-felsefe-ve-farklılaşma)
5. [Özellikler - Mağdur Modu](#5-özellikler--mağdur-modu)
6. [Özellikler - Kurtarıcı Modu](#6-özellikler--kurtarıcı-modu)
7. [Kullanıcı Akışları](#7-kullanıcı-akışları)
8. [Teknik Mimari](#8-teknik-mimari)
9. [UI/UX Prensipleri](#9-uiux-prensipleri)
10. [Lokal AI Detayları](#10-lokal-ai-detayları)
11. [BLE Beacon Detayları](#11-ble-beacon-detayları)
12. [Bilgi Tabanı (RAG)](#12-bilgi-tabanı-rag)
13. [Veri Modelleri](#13-veri-modelleri)
14. [Proje Yapısı](#14-proje-yapısı)
15. [Bağımlılıklar (pubspec.yaml)](#15-bağımlılıklar-pubspecyaml)
16. [Takım ve Sorumluluklar](#16-takım-ve-sorumluluklar)
17. [40 Saatlik Zaman Çizelgesi](#17-40-saatlik-zaman-çizelgesi)
18. [Demo Senaryosu](#18-demo-senaryosu)
19. [Risk Yönetimi](#19-risk-yönetimi)
20. [Gelecek Yol Haritası](#20-gelecek-yol-haritası)
21. [Yapay Zeka Asistanları İçin Talimatlar](#21-yapay-zeka-asistanları-için-talimatlar)

---

## 1. PROJE ÖZETİ

**Uygulama Adı:** Yanındayım
*Önceki ad: Yanında — geliştirme sırasında değiştirildi.*

**Tek cümle:** Deprem anında ve sonrasında mağdurlarla kurtarıcıları, internet olmasa bile bir araya getiren, lokal yapay zekayla psikolojik ve pratik destek sunan ücretsiz mobil uygulama.

**Etkinlik:** 40 saatlik AppJam hackathon.

**Platform:** iOS + Android (Flutter ile tek kod tabanı).

**Pazar:** Türkiye (sunumda v1 odağı olarak belirtilecek).

**İş modeli:** Tamamen ücretsiz, reklamsız, bağışla sürdürülen.

**Ana değer önerisi:** "İnternet yok, sinyal yok, panik var — uygulama yine yanında." Tüm kritik özellikler **offline** çalışır.

---

## 2. KISITLAMALAR VE BAĞLAM

| Kısıtlama | Değer |
|---|---|
| Geliştirme süresi | 40 saat (hackathon) |
| Takım | 3 kişi (Kemal, Emir, Serhat) |
| Stack | Flutter (Dart) |
| Hedef platformlar | Android 8+, iOS 14+ |
| Dil | Türkçe (v1) |
| Bütçe | Sıfır (ücretsiz/açık kaynak araçlar) |
| Yargı kriteri | Gerçek hayata uyarlanabilirlik en önemli kriter |

**40 saat içinde dürüstlük notu:** Üç kişi için bile gerçek bir sürpriz olmadan biten ~120 saatlik iş. Bu yüzden Tier 1 özelliklerine acımasız öncelik verilir.

---

## 3. HEDEF KULLANIcILAR

### Mağdur (Birincil)
- Yaş 16-70, akıllı telefon kullanan herkes
- Deprem öncesi indirir, deprem anında/sonrası kullanır
- Panik halinde, muhtemelen yaralı, batarya endişesi var
- **Yetersiz teknik bilgi varsayılır** — UI son derece sade olmalı

### Kurtarıcı (İkincil)
- AKUT, AFAD gönüllüsü, UMKE, profesyonel arama-kurtarma ekibi
- **Sertifika ile doğrulama** — uygulamada kayıt sırasında sertifika numarası girer
- Eğitimli olduğu için AI desteğine ihtiyacı yok — temiz, hızlı operasyonel arayüz
- Saha koşullarında: eldiven, ışıksız ortam, hızlı karar

---

## 4. FELSEFE VE FARKLILAŞMA

### Diğer deprem uygulamalarından farkımız:

| Pazarda var olan | Bizim farkımız |
|---|---|
| Bridgefy/Briar tarzı P2P mesajlaşma (kullanıcı yoğunluğu olmayınca işe yaramaz) | **BLE Beacon tek yönlü yayın** — enkaz altındaki telefon ekran kapalı bile sinyal verir, kurtarıcı tarayıcı bulur |
| iOS Emergency SOS, AFAD app, Yardım Et | **Otomatik tetik** + **sesli komut** + **görme engelli desteği** |
| Genel offline chatbot | **Hibrit PFA**: kritik psikolojik akış elle yazılmış, serbest sorular LLM ile |
| OsmAnd, Maps.me | **Sadece toplanma alanı + hastane + AFAD lojistik noktaları**, küçük boyut |
| Bağış uygulamaları | **Aggregator** — AKUT/Kızılay/AHBAP'a deeplink, kendi para işlemi yok (yasal yük yok) |

### Tasarım felsefesi: "Kriz dostu UI"
- Panik anında okunabilir tipografi
- Yatıştırıcı renk paleti (kırmızı/turuncu yerine derin yeşil)
- Her ekranda kullanıcıya "yanlız değilsin" mesajı
- Asla hata ekranı — her durum için anlamlı geri bildirim

---

## 5. ÖZELLİKLER — MAĞDUR MODU

### 5.1. Tek Tuş SOS [TIER 1]

**Senaryo:** Kullanıcı tek butona basar veya 5x güç tuşu kombinasyonuna basar.

**Akış:**
1. Buton basıldığında 5 saniyelik geri sayım başlar (iptal için tap)
2. Geri sayım biterse:
   - Düdük çalmaya başlar (aşağıda detay)
   - Ekranda büyük "KAPAT" butonu
   - "Konum X kişiye iletiliyor..." metni
3. 60 saniye boyunca kullanıcı **KAPAT** butonuna basmazsa:
   - SMS listesindeki 5 kişiye konum + "İmdat, deprem altındayım" SMS'i gönderilir
   - 112 otomatik aranır (kullanıcı izniyle önceden onaylanmış)
4. SMS gönderildikten sonra düdük çalmaya devam eder
5. Düdük şu durumlarda durur:
   - Kullanıcı KAPAT'a basar (telefon kilidi açılır + ekran kontrolü)
   - Sesli komut "düdüğü kapat" (görme engelli desteği)
   - Batarya biter

**Düdük tasarımı:**
- 3 kHz frekans (insan kulağı için en iyi duyulabilir, mesafe için iyi)
- **Aralıklı çalma:** 3 saniye ses, 2 saniye sessizlik — kurtarıcının seslenip cevap alabilmesi için
- WAV dosyası önceden üretilip assets/audio/whistle_3khz.wav olarak gömülür
- AudioPlayers paketi ile loop, telefon ses sistemini maksimuma alır
- Mors alfabesi ELE ALINMADI (kullanıcıların eğitimsiz olması nedeniyle, basit aralıklı tercih edildi)

**Sesli komut:**
- `speech_to_text` paketi, Türkçe offline dil paketi (cihazda yüklüyse)
- Sadece "düdüğü kapat" / "durdur" kelimeleri dinlenir
- Yanlış pozitifi minimize etmek için "imdat" gibi paniklenebilecek kelimeler kullanılmaz

### 5.2. BLE Beacon Yayını [TIER 1]

**Senaryo:** Kullanıcı enkaz altında, telefon ekranı kapalı, batarya kritik.

**Yayın içeriği (BLE advertisement packet):**
- Anonim kullanıcı ID (UUID v4, ilk kurulumda üretilir)
- Son bilinen GPS konumu (deprem anından önceki son okuma)
- Kan grubu (opsiyonel, kullanıcı kayıtta girdi)
- Kritik tıbbi notlar (1-2 etiket: "diyabet", "kalp", "alerji" vb.)
- Pil yüzdesi
- Yayın başlangıç zamanı (rescuer süreyi hesaplayabilsin)

**Davranış:**
- Otomatik olarak "Enkaz Modu" aktifleştiğinde başlar (ivmeölçer + 30 sn hareketsizlik + SOS basılmış olması)
- Veya manuel "Beacon Aç" butonu
- 2 saniyede bir paket gönderir (BLE düşük güç modu)
- Ekran kapalıyken bile çalışır (foreground service Android'de)
- iOS arka plan kısıtlamaları nedeniyle iOS'ta uygulamanın kilitlenmesini beklerken Background BLE Advertisement kullanılır (sınırlı ama çalışır)

**iOS kısıtlama notu (DEMO KRİTİK):** iOS uygulamayı arka plana attığında BLE advertisement'ın service UUID'si overflow alanına geçer. Demo için her iki cihazda da app foreground'da olur — yargı bunu sorarsa "ürünleşme aşamasında iCloud-benzeri özel teknik gerekir, v2 roadmap'inde" dürüstçe söylenir.

### 5.3. Güvendeyim Check-in [TIER 1]

**Senaryo:** Deprem sonrası kullanıcı sağ, ailesini haberdar etmek istiyor.

**Akış:**
- Ana ekranda "Güvendeyim" yeşil buton
- Tıklayınca 3 saniyelik onay
- SMS listesindeki 5 kişiye gönderilir: "Ben Kemal, güvendeyim. Konumum: https://maps.google.com/?q=lat,lng. Saat: HH:MM"
- Yanlış basmaya karşı 3 saniyelik geri sayım

### 5.4. Offline Toplanma Alanı Haritası [TIER 1]

**Veri:** AFAD'ın "Toplanma Alanları" listesi (afad.gov.tr/toplanma-alanlari-listesi). Tüm Türkiye için CSV/GeoJSON formatında uygulamaya gömülür.

**Görsel:** `flutter_map` paketi + offline tile cache (sadece kullanıcının ili indirilir, küçük tutmak için).

**Özellikler:**
- Mevcut konuma en yakın 3 toplanma alanı listelenir
- Yürüyüş rotası (offline routing zor, sadece düz çizgi + mesafe gösterilebilir v1'de)
- Hastane, AFAD lojistik merkezi katmanları açılıp kapatılabilir

### 5.5. Lokal AI Chatbot [TIER 2]

**Model:** Gemma 2B Q4 (~1.2 GB) veya Qwen 2.5 1.5B Q4 (~1.0 GB)
**Çalışma şekli:** flutter_gemma paketi ile cihazda inference (MediaPipe LLM Inference API üzerinden)

**RAG akışı:**
1. Kullanıcı soru yazar/söyler ("Toplanma alanı nerede?")
2. Soru, paraphrase-multilingual-MiniLM ile embedding'e dönüştürülür (cihazda)
3. Bilgi tabanındaki ~50 chunk'ın embedding'leriyle cosine similarity hesaplanır
4. En yakın 3 chunk seçilir
5. LLM'e "Şu bilgileri kullanarak Türkçe ve sade cevap ver: [chunks]" prompt'u verilir
6. Cevap stream olarak ekranda yazılır

**UI:**
- WhatsApp benzeri sohbet ekranı
- Üstte sabit bant: "İnternet olmadan yanındayım — çevrimdışı asistan"
- Yazma sırasında titreyen "..." göstergesi
- Hızlı sorular (chips): "Toplanma alanı?", "İlk yardım", "Yıkıntı altındayım", "Çocuğum nerede?"

### 5.6. PFA — Psikolojik İlk Yardım Modu [TIER 2]

**KRİTİK:** Bu **AI değil**. Elle yazılmış decision tree akışıdır. Risksiz, anında çalışır.

**Tasarım:** WHO ve Kızılay PFA Pocket Guide'ından çıkarılmış ~30 ekranlık akış.

**Örnek akış:**
1. "Şu an nasıl hissediyorsun?" → [Korkuyorum / Nefes alamıyorum / Yakınımı kaybettim / Yaralıyım]
2. "Nefes alamıyorum" seçilirse → Nefes egzersizi ekranı
   - 4 saniye nefes al, 7 saniye tut, 8 saniye ver
   - Büyüyen-küçülen yeşil daire animasyonu
   - "Birlikte yapalım, ben buradayım"
3. "Yakınımı kaybettim" seçilirse → Yas için PFA prensipleri
   - "Hissettiklerin doğal"
   - "Bilgi almak istersen, yakındaki AFAD aile birleştirme noktası: X"
4. Her ekranda alt butonlar: "Devam", "Geri", "Yardım çağır"

**Format:** assets/pfa_flow.json dosyasında. Yapı:
```json
{
  "nodes": {
    "root": {
      "title": "Şu an nasıl hissediyorsun?",
      "options": [
        {"label": "Korkuyorum", "next": "fear_1"},
        {"label": "Nefes alamıyorum", "next": "breathing_1"}
      ]
    },
    "breathing_1": {
      "title": "Birlikte nefes alalım",
      "widget": "BreathingExercise",
      "params": {"inhale": 4, "hold": 7, "exhale": 8, "cycles": 5},
      "next_button": "breathing_2"
    }
  }
}
```

### 5.7. Bağış Sayfası [TIER 3]

Tek ekran, kuruluş logoları grid'i:
- AKUT → akut.org.tr
- Kızılay → kizilay.org.tr
- AHBAP → ahbap.org
- İhtiyaç Haritası → ihtiyacharitasi.org
- AFAD Resmi Bağış → afad.gov.tr

Her logoya tıklayınca `url_launcher` ile harici tarayıcıda açılır. Uygulamamızda para işlemi yok.

---

## 6. ÖZELLİKLER — KURTARICI MODU

Kurtarıcı modu mağdur modundan **daha sade**. AI yok, PFA yok. Operasyonel verimlilik öncelik.

### 6.1. Sertifikalı Kayıt [TIER 1]

İlk kurulumda kurtarıcı modunu seçen kullanıcıdan:
- Ad-Soyad
- Kuruluş (AKUT/AFAD/UMKE vb. dropdown)
- Sertifika numarası
- Uzmanlık alanı (arama-kurtarma, sağlık, lojistik, vb.)

v1'de doğrulama elle yapılmaz, sadece kayıt alınır. v2'de kuruluşlarla entegrasyon planlanır.

### 6.2. Mağdur Beacon Tarama Haritası [TIER 1]

**Ana ekran.** Açıldığı anda BLE taraması başlar.

**Görünüm:**
- Tam ekran harita (mevcut konum merkezde)
- Algılanan beacon'lar pin olarak
- Pin rengi: yeşil (yeni, pil yüksek) → sarı (uzun süre, pil düşük) → kırmızı (kritik)
- Pin'e dokunulduğunda alt panel açılır:
  - Anonim ID
  - Son konum + mesafe ("12 m kuzeydoğu")
  - Pil seviyesi
  - Kan grubu, tıbbi notlar
  - Yayın süresi ("3 saat 24 dakika"dır yayında)
  - "Yön Bul" butonu (pusula yönlendirmesi)

### 6.3. Yön Bulma (BLE Sinyal Gücü) [TIER 2]

BLE RSSI (Received Signal Strength) sinyalin yakınlığını tahmin eder. Çok hassas değil ama enkaz odasında "soğuk-sıcak" oyunu mantığıyla çalışır:
- RSSI -90 dBm → çok uzak, kırmızı
- RSSI -70 dBm → yaklaşılıyor, sarı
- RSSI -50 dBm → yakın, yeşil
- RSSI -30 dBm → çok yakın, koyu yeşil + titreşim

UI: Büyük yeşillenen daire + "Yaklaşıyorsun" / "Uzaklaşıyorsun" metni.

### 6.4. Triaj Kartı [TIER 2]

START / JumpSTART protokolünün özet kartı (Türkçe). Statik ekran, içerik:
- Yürüyebiliyor mu? → Yeşil (gecikmiş)
- Solunum var mı? Yoksa hava yolu açma sonrası kontrol et → Siyah (ex) / Kırmızı (acil)
- Solunum hızı? → Kırmızı (>30 veya <10) / Sarı
- Kapiller dolum? > 2 sn → Kırmızı

Görsel olarak akış şeması + her durum için tek satır müdahale notu.

### 6.5. Toplanma Alanı + Lojistik Harita [TIER 1, Mağdur ile ortak]

Mağdur modundaki harita aynı, sadece ek katman: AFAD lojistik noktaları, AKUT toplanma noktaları.

### 6.6. Gönüllü Listesi [TIER 3, Opsiyonel]

Aynı bölgedeki diğer kurtarıcıları gösteren basit liste (BLE üzerinden de tespit edilebilir kurtarıcı moddaki cihazlar). v1'de basit liste yeterli.

---

## 7. KULLANICI AKIŞLARI

### 7.1. İlk Açılış Akışı

```
Splash → 
  Dil seçimi (TR/EN gizli, v1 sadece TR) → 
  Mod seçimi (Mağdur / Kurtarıcı) →
  [Mağdur seçildi]:
    İzinler (Konum, Bluetooth, SMS, Mikrofon)
    → Acil kişi listesi ekle (en az 1, en fazla 5)
    → Kan grubu ve tıbbi bilgi (opsiyonel)
    → AI paketi indirme önerisi (~1.2 GB, WiFi tavsiye)
    → Ana ekran
  [Kurtarıcı seçildi]:
    Sertifika bilgileri formu
    İzinler (Konum, Bluetooth)
    → Ana ekran (tarama haritası)
```

### 7.2. Deprem Anı — Mağdur Akışı

```
Sallanma algılandı (ivmeölçer >2.5g) →
  Tam ekran kırmızı uyarı + ses: "DEPREM - ÇÖK KAPAN TUTUN"
  → 15 sn animasyon
  → "Güvende misin?" ekranı
    [Evet] → Güvendeyim check-in akışı
    [Hayır] → SOS akışı otomatik tetiklenir
    [10 sn yanıt yoksa] → SOS otomatik tetiklenir
```

### 7.3. Enkaz Altı Akışı

```
SOS tetiklendi → 
  Düdük başlar →
  60 sn kullanıcı tepki vermez → 
    SMS gönderildi + 112 arandı →
    Beacon yayını başlar →
    Ekran "Düşük Güç Modu"na geçer (siyah ekran, sadece KAPAT butonu)
    Düdük dönmeye devam eder
    Beacon yayına devam eder
```

### 7.4. Kurtarıcı Akışı

```
Uygulama açılır → 
  Otomatik tarama başlar →
  Yakındaki beacon'lar haritada görünür →
  Pin'e tıklandı → Detay paneli →
  "Yön Bul" → Sinyal gücü ekranı (sıcak-soğuk)
  Mağdura ulaşıldı → "Kurtarıldı olarak işaretle" → 
    Beacon listeden kaldırılır (yerel)
```

---

## 8. TEKNİK MİMARİ

### Stack Özeti
- **Framework:** Flutter 3.19+ (Dart 3.3+)
- **Hedef SDK:** Android API 26+ (8.0), iOS 14+
- **Mimari Desen:** Feature-first folder structure + Provider/Riverpod state management
- **State management:** Riverpod 2.x (basit ve test edilebilir)
- **Yerel veri:** Hive (basit key-value), SharedPreferences (config)
- **Yapay zeka:** flutter_gemma (MediaPipe LLM Inference API wrapper)

### Servisler Katmanı

| Servis | Sorumluluk |
|---|---|
| `BleService` | Beacon yayını ve tarama, RSSI okuma |
| `AiService` | Model yükleme, RAG arama, LLM inference |
| `LocationService` | Konum okuma, son konum cache |
| `SmsService` | SMS gönderimi (`url_launcher` ile sms: intent) |
| `AudioService` | Düdük çalma/durdurma, ses kontrolü |
| `VoiceService` | Sesli komut dinleme (offline) |
| `SensorService` | İvmeölçer ile deprem/hareketsizlik tespiti |
| `MapService` | Offline tile yönetimi, toplanma alanı verisi |

### Veri Akışı

```
UI (Widget) ↔ ViewModel (Riverpod) ↔ Repository ↔ Service ↔ Native (BLE/AI/Sensor)
```

---

## 9. UI/UX PRENSİPLERİ

### Renk Paleti

| Renk | Kullanım | Hex |
|---|---|---|
| Derin Yeşil | Primary (yatıştırıcı) | `#0F3D2E` |
| Krem | Background | `#F4EDE0` |
| Açık Yeşil | Success, beacon aktif | `#4CAF7A` |
| Soft Sarı | Uyarı (panik yapmasın) | `#E8C547` |
| Tonal Kırmızı | Sadece kritik aksiyon | `#C04F4F` |
| Koyu Gri | Metin | `#2A2A2A` |
| Açık Gri | İkincil metin | `#6B6B6B` |

**Önemli:** Kırmızı sadece "112 Ara" gibi tek aksiyon için. Acil durum UI'larında kırmızı dolu ekran kullanmıyoruz çünkü panik artırır.

### Tipografi
- Font: **Inter** (Google Fonts üzerinden, offline gömülü)
- Gövde: 16 sp, regular
- Başlık 1: 32 sp, bold
- Başlık 2: 24 sp, semibold
- Buton: 18 sp, medium
- Min satır yüksekliği: 1.5x

### Dokunma Hedefleri
- Min boyut: 60×60 dp (deprem sonrası titreyen eller)
- Butonlar arası min 16 dp boşluk
- Ana SOS butonu: ekranın %40'ı

### Animasyon Prensipleri
- 200-400 ms arası geçişler (çok hızlı sıkıntı, çok yavaş sabırsızlık)
- Easing: `Curves.easeInOutCubic`
- Nefes egzersizi: 4-7-8 ritmi (klinik kanıtlı panik düşürür)
- Beacon aktif animasyonu: 2 saniyede bir genişleyen dalga (nabız etkisi)

### Sabit Durum Şeritleri
Her ekranın üstünde küçük durum bandı:
- **Beacon aktif:** Yeşil nokta + "Sinyaliniz yayında"
- **AI hazır:** Mavi nokta + "Çevrimdışı asistan hazır"
- **Batarya düşük:** Sarı uyarı + "Düşük güç moduna geçilebilir"

### Kullanıcıya Asla Söylenmemesi Gerekenler
- "Hata oluştu"
- "Bağlantı yok"
- "Geçersiz"
- "İzin reddedildi"

Yerine: "İnternet olmadan da yanındayım", "Tekrar denemek için dokun", "Önce konum izni veriyoruz?"

---

## 10. LOKAL AI DETAYLARI

### Model Seçimi

**Birincil tercih:** Gemma 2B Instruct, INT4 sıkıştırma, ~1.2 GB
- Avantaj: Google'ın flutter_gemma resmi paketi var
- Dezavantaj: Türkçe orta seviye, RAG ile destek şart

**Alternatif:** Qwen 2.5 1.5B Instruct INT4, ~1.0 GB
- Avantaj: Türkçe daha iyi
- Dezavantaj: Flutter entegrasyonu manuel (llama.cpp + FFI)

**Hackathon kararı:** Gemma 2B (hızlı entegrasyon).

### Model İndirme Akışı
1. İlk açılışta kullanıcıya sorulur: "Çevrimdışı koruma paketi indirilsin mi? (~1.2 GB, WiFi tavsiye edilir)"
2. Kabul ederse arka planda indirilir
3. İndirme tamamlanmadan uygulama çalışır ama AI özellikleri devre dışı kalır
4. İndirme yarıda kalırsa devam edilir
5. İndirme tamamlandığında bildirim: "Yapay zeka asistanınız hazır"

### RAG Yapısı

**Embedding modeli:** paraphrase-multilingual-MiniLM-L12-v2 (~120 MB)

**Önceden hesaplama (build time, Python script ile):**
```python
# scripts/build_knowledge_base.py
from sentence_transformers import SentenceTransformer
import json

model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

chunks = load_documents()  # 50 chunk, her biri ~500 kelime
embeddings = model.encode([c['text'] for c in chunks])

output = [{'id': c['id'], 'text': c['text'], 'source': c['source'],
           'embedding': emb.tolist()} for c, emb in zip(chunks, embeddings)]

with open('assets/knowledge_base/chunks.json', 'w') as f:
    json.dump(output, f, ensure_ascii=False)
```

**Runtime sorgu (Flutter):**
```dart
class AiService {
  Future<String> answerQuery(String query) async {
    // 1. Soru için embedding üret (cihazda)
    final queryEmbedding = await _embed(query);

    // 2. Bilgi tabanında cosine similarity
    final chunks = await _loadChunks();
    final scored = chunks.map((c) => MapEntry(c, _cosine(queryEmbedding, c.embedding))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    final top3 = scored.take(3).map((e) => e.key.text).join('\n\n');

    // 3. LLM prompt
    final prompt = '''
Aşağıdaki Türkçe bilgileri kullanarak kullanıcının sorusuna sade ve sakin cevap ver.
Bilmediğini bilmiyorum de, uydurma.

BİLGİLER:
$top3

SORU: $query

CEVAP:
''';

    // 4. Stream cevabı
    return await _llm.generate(prompt);
  }
}
```

### Performans Beklentisi
- İlk yanıt: ~3-5 saniye (model yüklendikten sonra)
- Token üretimi: ~10-20 token/saniye (orta cihaz, mid-range Android)
- Maksimum yanıt: 200 token (zaten kısa cevap istiyoruz)

### PFA Modu — AI Değil
Tekrar vurgulanır: PFA bir state machine'dir, LLM'e dokunmaz. assets/pfa_flow.json dosyasından yüklenir, koşulsuz çalışır, asla başarısız olmaz.

---

## 11. BLE BEACON DETAYLARI

### Yayın Formatı (Mağdur)

iBeacon benzeri özel format kullanılır. BLE Manufacturer Data alanı:

```
Bytes 0-15:   User UUID (anonim)
Bytes 16-19:  Latitude (float)
Bytes 20-23:  Longitude (float)
Byte 24:      Battery percentage (0-100)
Byte 25:      Blood type code (0=bilinmiyor, 1=A+, 2=A-, ...)
Byte 26:      Medical flags (bitfield: diyabet, kalp, alerji vb.)
Bytes 27-30:  Beacon start timestamp (UNIX, 32-bit)
```

Toplam 31 byte (BLE advertisement maksimum).

### Yayın Davranışı (Mağdur tarafı)
- Advertising interval: 2000 ms (pil tasarrufu)
- TX power: medium (mesafe vs pil dengesi)
- Foreground service ile arka planda kalır (Android)
- iOS: app açıkken full, kapandığında overflow area (sınırlı)

### Tarama (Kurtarıcı tarafı)
- Sürekli aktif tarama (scan duty cycle: 100%)
- Filtreleme: sadece bizim app'in manufacturer ID'si
- RSSI okuması her pakette
- Bulunduktan sonra 30 saniye boyunca güncellenmezse "kayıp" işaretlenir

### Yön Bulma Algoritması
RSSI'den mesafe tahmini güvenilir değil ama göreceli yakınlık için kullanılır:
```
distance ≈ 10 ^ ((TxPower - RSSI) / (10 * n))
```
n = ortam katsayısı (2 = boş alan, 3-4 = enkaz)

Demoda mutlak mesafe değil, "yaklaşıyorsun/uzaklaşıyorsun" trend gösterilir.

---

## 12. BİLGİ TABANI (RAG)

### Doküman Kaynakları

| Kategori | Kaynak | Doküman |
|---|---|---|
| Resmi | AFAD | Deprem Öncesi Hazırlık |
| Resmi | AFAD | Deprem Anında Yapılacaklar |
| Resmi | AFAD | Deprem Sonrası İlk 72 Saat |
| Resmi | AFAD | Deprem Çantası İçeriği |
| Resmi | AFAD | Toplanma Alanları Listesi (CSV, il bazlı) |
| Sağlık | Kızılay | Temel İlk Yardım El Kitabı |
| Sağlık | Sağlık Bakanlığı | Temel Yaşam Desteği Rehberi |
| Sağlık | UMKE | START Triaj Protokolü (Türkçe) |
| Psikoloji | Kızılay | PFA Saha Çalışan Kılavuzu (WHO çevirisi) |
| Psikoloji | WHO | PFA Pocket Guide (TR çeviri) |
| Yapısal | İBB / AFAD | Bina Hasar Tespit Rehberi |
| Yapısal | TMMOB | Deprem Sonrası Yapısal Risk |

### Chunk Stratejisi
- Her doküman 300-500 kelimelik chunk'lara bölünür
- Her chunk'a: id, source, category, text, embedding eklenir
- Hedef toplam: ~50 chunk (~25 MB JSON)

### İlk 10 Chunk Örneği (manuel hazırlık için)
1. "Deprem öncesi evde alınacak önlemler — Mobilyaları sabitleme..."
2. "Deprem anında çök-kapan-tutun pozisyonu..."
3. "Enkaz altında kalırsanız: Hareketsiz kalın, pil tasarrufu..."
4. "Toplanma alanına nasıl gidilir, ne götürülür..."
5. "Açık kırıklarda kanama durdurma..."
6. "Bilinç kontrolü AVPU yöntemi..."
7. "PFA bakma-dinleme-yönlendirme prensibi..."
8. "Çocukla afet sonrası nasıl konuşulur..."
9. "Yas süreci ve normal tepkiler..."
10. "Aile birleştirme noktaları nasıl çalışır..."

---

## 13. VERİ MODELLERİ

### User
```dart
class User {
  String id;              // UUID v4, ilk kurulumda üretilir
  UserMode mode;          // victim | rescuer
  String? name;
  String? bloodType;
  List<String> medicalFlags;
  List<EmergencyContact> emergencyContacts;
  RescuerCredentials? rescuerCreds;  // Sadece kurtarıcı modu
  DateTime createdAt;
}

enum UserMode { victim, rescuer }
```

### EmergencyContact
```dart
class EmergencyContact {
  String name;
  String phoneE164;  // +905XXXXXXXXX
}
```

### Beacon
```dart
class Beacon {
  String anonymousId;
  double latitude;
  double longitude;
  int batteryPercent;
  String bloodType;
  List<String> medicalFlags;
  DateTime broadcastStarted;
  int rssi;              // Sadece kurtarıcı tarafı
  DateTime lastSeen;
}
```

### KnowledgeChunk
```dart
class KnowledgeChunk {
  String id;
  String source;
  String category;
  String text;
  List<double> embedding;  // 384 boyut (MiniLM)
}
```

---

## 14. PROJE YAPISI

```
yaninda/
├── android/                    # Native Android config
├── ios/                        # Native iOS config
├── lib/
│   ├── main.dart              # Uygulama girişi
│   ├── app.dart               # MaterialApp, routing setup
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData
│   │   │   ├── colors.dart          # AppColors sabitleri
│   │   │   └── typography.dart      # TextStyle setleri
│   │   ├── routing/
│   │   │   └── app_router.dart      # go_router config
│   │   ├── services/
│   │   │   ├── ble_service.dart
│   │   │   ├── ai_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── sms_service.dart
│   │   │   ├── audio_service.dart
│   │   │   ├── voice_service.dart
│   │   │   ├── sensor_service.dart
│   │   │   └── map_service.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── beacon.dart
│   │   │   ├── knowledge_chunk.dart
│   │   │   └── user_mode.dart
│   │   └── utils/
│   │       ├── audio_utils.dart
│   │       └── distance_utils.dart
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── mode_selection_screen.dart
│   │   │   ├── permissions_screen.dart
│   │   │   ├── contacts_setup_screen.dart
│   │   │   └── medical_info_screen.dart
│   │   │
│   │   ├── victim/
│   │   │   ├── home/
│   │   │   │   └── victim_home_screen.dart
│   │   │   ├── sos/
│   │   │   │   ├── sos_button.dart
│   │   │   │   ├── sos_active_screen.dart
│   │   │   │   └── sos_controller.dart
│   │   │   ├── beacon/
│   │   │   │   └── beacon_status_screen.dart
│   │   │   ├── chat/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   ├── message_bubble.dart
│   │   │   │   └── chat_controller.dart
│   │   │   ├── pfa/
│   │   │   │   ├── pfa_screen.dart
│   │   │   │   ├── pfa_engine.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── breathing_exercise.dart
│   │   │   │       └── choice_buttons.dart
│   │   │   ├── map/
│   │   │   │   └── assembly_map_screen.dart
│   │   │   ├── checkin/
│   │   │   │   └── safe_checkin_screen.dart
│   │   │   └── donation/
│   │   │       └── donation_screen.dart
│   │   │
│   │   ├── rescuer/
│   │   │   ├── registration/
│   │   │   │   └── rescuer_register_screen.dart
│   │   │   ├── scanner/
│   │   │   │   ├── scanner_map_screen.dart
│   │   │   │   ├── victim_detail_sheet.dart
│   │   │   │   └── direction_finder_screen.dart
│   │   │   └── triage/
│   │   │       └── triage_card_screen.dart
│   │   │
│   │   └── shared/
│   │       └── widgets/
│   │           ├── status_banner.dart
│   │           ├── big_button.dart
│   │           └── calm_loader.dart
│   │
│   └── data/
│       ├── repositories/
│       │   ├── user_repository.dart
│       │   └── beacon_repository.dart
│       └── seed/
│           └── assembly_areas.dart  # Embedded
│
├── assets/
│   ├── audio/
│   │   ├── whistle_3khz.wav
│   │   ├── breathing_guide.mp3
│   │   └── earthquake_alert.mp3
│   ├── images/
│   │   ├── logo.png
│   │   ├── ngos/  # Bağış sayfası için
│   │   └── icons/
│   ├── pfa_flow.json            # PFA decision tree
│   ├── knowledge_base/
│   │   └── chunks.json          # RAG chunks + embeddings
│   ├── maps/
│   │   └── assembly_areas.geojson
│   └── ai_model/
│       └── README.md            # Model runtime'da indirilir
│
├── scripts/
│   ├── build_knowledge_base.py  # Embedding üretme
│   └── generate_whistle.py      # 3 kHz WAV üretme
│
├── test/
│   └── ... (Tier 3, hackathon'da minimum)
│
├── pubspec.yaml
└── README.md
```

---

## 15. BAĞIMLILIKLAR (pubspec.yaml)

```yaml
name: yaninda
description: Deprem hayatta kalma ve kurtarma uygulaması
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1

  # Routing
  go_router: ^14.0.0

  # BLE
  flutter_blue_plus: ^1.32.12
  # Alternatif: flutter_reactive_ble: ^5.3.1

  # AI
  flutter_gemma: ^0.4.0
  # Eğer flutter_gemma yetersizse: tflite_flutter ile manuel

  # Audio
  audioplayers: ^6.0.0
  just_audio: ^0.9.37  # Yedek

  # Voice (offline)
  speech_to_text: ^6.6.0

  # Location
  geolocator: ^11.0.0

  # SMS & call
  url_launcher: ^6.2.5

  # Maps
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # Sensors
  sensors_plus: ^4.0.2

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # Background work
  flutter_background_service: ^5.0.5

  # Permissions
  permission_handler: ^11.3.0

  # UI
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0

  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/audio/
    - assets/images/
    - assets/images/ngos/
    - assets/images/icons/
    - assets/pfa_flow.json
    - assets/knowledge_base/chunks.json
    - assets/maps/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 16. TAKIM VE SORUMLULUKLAR

### Kemal (Lead, UI/UX odaklı)
- Tasarım sistemi: renkler, tipografi, ortak widget'lar
- Mod seçim ekranı, onboarding akışı
- SOS akışı UI: buton, geri sayım, aktif ekran
- Düdük servisi (audio + voice control)
- PFA ekranları + decision tree engine + breathing exercise
- Güvendeyim check-in
- Bağış sayfası (deeplink'ler)
- Demo videosu, sunum slaytları, pitch
- Takım koordinasyonu, daily standup

### Emir (BLE uzmanı)
- BLE Beacon yayın servisi (mağdur)
- BLE Tarama servisi (kurtarıcı)
- Foreground service kurulumu (Android arka plan)
- iOS BLE permission ve background handling
- Kurtarıcı tarama haritası ekranı
- Mağdur detay paneli (alt sheet)
- Yön Bulma ekranı (RSSI tabanlı)
- Sensor servisi (ivmeölçer ile deprem algılama)
- Enkaz Modu (otomatik tetik + ekran karartma)

### Serhat (AI + Harita uzmanı)
- flutter_gemma kurulumu, model indirme akışı
- Embedding hesaplama script'i (Python, build time)
- RAG arama servisi (Dart)
- Chatbot ekranı (sohbet UI'si)
- Bilgi tabanı kürasyonu (50 chunk hazırlama)
- Offline harita: flutter_map + tile cache
- Toplanma alanı verisi (GeoJSON)
- AFAD lojistik nokta katmanı
- Triaj kartı ekranı (kurtarıcı modu)

---

## 17. 40 SAATLİK ZAMAN ÇİZELGESİ

### FAZ 1 — KURULUM (Saat 0-6) — TÜM TAKIM PARALEL

**0-2:** Birlikte
- Repo açma, Flutter proje init
- Klasör yapısı oluşturma
- pubspec.yaml bağımlılıkları
- Git branch stratejisi
- Tasarım skeçleri (Figma veya kağıt)

**2-6:** Paralel
- **Kemal:** Tema, renkler, tipografi, ortak widget'lar (BigButton, StatusBanner, CalmLoader). Mod seçim ekranı.
- **Emir:** BLE permission setup (Android Manifest, iOS Info.plist), flutter_blue_plus testleri, hello-world advertisement.
- **Serhat:** flutter_gemma kurulumu, model indirme akışı, dummy chatbot ekranı. Python build script'i için bilgi tabanı dokümanlarını toplama.

**Saat 6 checkpoint:** Mod seçimi çalışır mı? BLE izinler alındı mı? Model indirme akışı görülebiliyor mu?

### FAZ 2 — ÇEKİRDEK ÖZELLİKLER (Saat 6-14)

**Kemal (SOS + Düdük):**
- 6-8: SOS butonu + geri sayım UI
- 8-11: AudioService — düdük çalma/durdurma, aralıklı pattern
- 11-13: SMS gönderimi + 112 arama (url_launcher)
- 13-14: 60 saniye timer akışı

**Emir (BLE Beacon Yayın):**
- 6-9: Manufacturer data formatı, encoding/decoding
- 9-12: Yayın servisi (mağdur tarafı)
- 12-14: Foreground service (Android), arka planda devam etme testi

**Serhat (AI Setup):**
- 6-8: Model indirildikten sonra yükleme
- 8-10: Basit prompt → cevap akışı (RAG'sız)
- 10-12: Bilgi tabanı için 20 chunk manuel hazırlama
- 12-14: Python script ile embedding hesaplama, JSON üretme

**Saat 14 checkpoint:** SOS basılınca düdük çalıyor mu? Beacon yayın aktif mi? AI basit soruya cevap verebiliyor mu?

### FAZ 3 — ENTEGRASYON (Saat 14-22)

**Kemal (PFA Modu):**
- 14-16: pfa_flow.json yapısını oluşturma
- 16-18: PFA Engine (decision tree state machine)
- 18-20: PFA UI ekranları (choice buttons, text screens)
- 20-22: Nefes egzersizi widget'ı (4-7-8 animasyonu)

**Emir (Tarama Haritası):**
- 14-17: BLE tarama servisi (kurtarıcı tarafı)
- 17-20: Tarama haritası ekranı (flutter_map üzerinde beacon pin'leri)
- 20-22: Mağdur detay alt paneli (bottom sheet)

**Serhat (RAG + Chatbot):**
- 14-16: RAG arama (cosine similarity, top-3 chunk)
- 16-19: Prompt engineering, sistem prompt'u yazma
- 19-22: Chatbot UI (mesaj bubble'ları, stream output, hızlı sorular)

**Saat 22 checkpoint:** PFA akışı en az 3 dal çalışıyor mu? Kurtarıcı haritada beacon görüyor mu? Chatbot "Toplanma alanı nerede?" sorusuna anlamlı cevap veriyor mu?

### FAZ 4 — TAMAMLAMA (Saat 22-30)

**Kemal:**
- 22-24: Sesli komut entegrasyonu (düdük durdurma için)
- 24-26: Güvendeyim check-in akışı
- 26-28: Bağış sayfası (logo grid + deeplink'ler)
- 28-30: Onboarding akış polish, ilk açılış deneyimi

**Emir:**
- 22-25: Yön bulma ekranı (RSSI tabanlı sıcak-soğuk)
- 25-27: Sensor service (ivmeölçer ile deprem algılama)
- 27-30: Enkaz modu otomatik tetik akışı

**Serhat:**
- 22-25: Offline harita tile cache (sadece bir il için demo)
- 25-27: Toplanma alanı GeoJSON entegrasyonu + harita üstünde gösterme
- 27-30: Triaj kartı ekranı + bilgi tabanına son chunk'lar

**Saat 30 checkpoint:** Tüm Tier 1 ve Tier 2 özellikler çalışıyor mu? Cihazda gerçekten test edildi mi?

### FAZ 5 — ENTEGRASYON TESTLERİ (Saat 30-36)

**Tüm takım, paralel test:**

**30-32: Mağdur senaryosu uçtan uca**
- Yeni cihazda kur → onboarding → izinler → SOS bas → düdük → SMS → beacon
- Hatalar listele, düzelt

**32-34: Kurtarıcı senaryosu uçtan uca**
- İkinci cihazda kurtarıcı kur → tarama → beacon bul → detay aç → yön bul
- Hatalar listele, düzelt

**34-36: AI/PFA testleri**
- 20 farklı soru AI'a sor, cevap kalitesi ölç
- PFA akışının tüm dallarını dolaş
- Düşük güç modunda davranış

### FAZ 6 — DEMO HAZIRLIĞI (Saat 36-40)

**Kemal:**
- 36-37: Pitch deck (10-15 slayt): problem, çözüm, demo, takım, roadmap
- 37-39: Demo video çekimi (2-3 dakika): mağdur senaryosu + kurtarıcı senaryosu, ekran kaydı + ses anlatımı
- 39-40: Son düzeltmeler

**Emir + Serhat:**
- 36-38: Bug fix son tur
- 38-40: Demo cihazlarında temiz kurulum, model önceden indirilmiş, beacon önceden test edilmiş

### Tampon Stratejisi
40 saatte mutlaka aksaklık olur. **Tampon:** Tier 3 özellikleri (Bağış sayfası, Gönüllü listesi, Triaj detayları) son anda eklenir veya tamamen atlanır. Asla Tier 1 özelliği için kısıtlama yapılmaz.

---

## 18. DEMO SENARYOSU (Sunum İçin)

### Hikaye: "İki Telefon, Bir Hayat"

**Sahne 1 (30 sn):** Karanlık bir oda. Telefon enkazda. Mağdur (Kemal) yaralı.
- "İnternet yok, kimse yok ama uygulama var"
- SOS butonuna basılır
- Düdük çalmaya başlar
- 60 saniye geçer (hızlandırılmış kurgu)
- SMS gönderiliyor animasyonu
- Beacon aktif olur, "Sinyaliniz yayında" mesajı

**Sahne 2 (30 sn):** Dışarıda kurtarıcı (Emir) elinde telefon.
- Kurtarıcı uygulamayı açar
- Tarama haritası boş, sonra ilk beacon görünür
- Pin'e dokunur, detay açılır: kan grubu, son konum, pil seviyesi
- "Yön Bul" butonuna basar
- Sıcak-soğuk göstergesi yeşilleşir
- Yaklaşıldığında titreşim

**Sahne 3 (20 sn):** Mağdur kurtarıldıktan sonra.
- Tekrar mağdur ekranı, "Güvendeyim" basar
- AI chatbot açılır: "Yıkıntıdan çıktım ama çok korkuyorum"
- AI yanıt verir, PFA modunu önerir
- Nefes egzersizi başlar (yeşil daire animasyonu)

**Sahne 4 (15 sn):** Toplanma alanı haritası
- Harita açılır
- Yakın 3 toplanma alanı pin'leri
- "En yakın: Kuşadası İlkokulu, 240 m"

**Sahne 5 (15 sn):** Bağış ekranı
- Logo grid'i
- AKUT logosuna dokunulur, dış tarayıcıda site açılır

### Sunum İçin Anahtar Cümleler
- "İnternet olmasa bile yanında"
- "Bluetooth ile enkaz altındaki sesi duyuyoruz"
- "Yapay zeka, internet olmadan bile psikolojik destek veriyor"
- "Tek uygulamada hem hayatta kalma hem kurtarma"

### Beklenen Jüri Sorulari ve Cevaplar
| Soru | Cevap |
|---|---|
| BLE menzili enkaz altında yeterli mi? | "Test ettik: 1-2 katı betona kadar çalışıyor. Mevcut alternatif sıfır." |
| Pek çok uygulama var, farkınız ne? | "Tek tıkla mağdur-kurtarıcı eşleştirme, hiçbirinde yok. Ayrıca tüm kritik özellikler offline." |
| Lokal AI gerçekten çalışıyor mu? | "Gemma 2B cihazda çalışıyor, 3-5 saniyede cevap. Canlı gösterebiliriz." |
| Kötü niyetli kurtarıcı sertifikası taklit ederse? | "v1'de elle doğrulama yok, v2'de AKUT/AFAD entegrasyonu planlı." |
| iOS arka planda BLE kısıtlı, çözüm ne? | "Doğru, v1'de uygulama açık kalmalı. v2'de iCloud-benzeri özel çözüm planlı." |

---

## 19. RİSK YÖNETİMİ

| Risk | Olasılık | Etki | Önlem |
|---|---|---|---|
| flutter_gemma çalışmaz | Orta | Yüksek | Yedek: TFLite + küçük model (Gemma 2B yerine TinyLlama) |
| iOS BLE arka plan kısıtlı | Yüksek | Orta | Demoda iki cihaz da foreground'da; sunumda dürüstçe açıkla |
| Model indirme süresi uzun | Orta | Düşük | Demoda model önceden indirilmiş cihaz kullan |
| Düdük sesi cihazda çıkmaz | Düşük | Orta | Birden çok cihazda test, alternatif: just_audio fallback |
| Sensor false trigger (deprem algı) | Yüksek | Düşük | Eşiği yüksek tut (>2.5g), 1.5 saniye süreklilik |
| Takımdan biri hasta olursa | Düşük | Yüksek | Pair programming, kritik bilgi paylaşımı, Tier 3 atlama |
| 40 saat yetmez | Yüksek | Yüksek | Acımasız priority: Tier 1 her zaman, Tier 3 son anda |

---

## 20. GELECEK YOL HARİTASI

### v2 (Hackathon sonrası 3 ay)
- AKUT/AFAD ile resmi entegrasyon (sertifika doğrulama)
- iOS arka plan BLE çözümü (Apple Watch + iPhone kombinasyonu)
- Bina risk skoru özelliği (adres → yapı yılı + zemin tipi + risk)
- Crowdsourced erken uyarı (telefon ivmeölçerleriyle P-dalga ağı)
- Çoklu dil: Arapça, İngilizce

### v3 (6-12 ay)
- Hasar tespit fotoğrafı + AI sınıflandırma
- Aile birleştirme platformu
- Gönüllü eşleştirme (yardım veren-isteyen marketplace)
- B2B: Belediye/sigorta entegrasyonu
- Apple Watch + Wear OS uygulaması (nabız, düşme algısı)

### Pazara Çıkış
- v1 hackathon sonrası → App Store + Play Store ücretsiz yayınla
- Kızılay/AKUT ile resmi tanıtım anlaşması
- AFAD onayı (DETSİS sistemi üzerinden)
- Sosyal medya kampanyası (deprem yıldönümlerinde)
- B2G satış: belediyelere lisanslı versiyon (özelleştirilebilir lojistik harita)

---

## 21. YAPAY ZEKA ASİSTANLARI İÇİN TALİMATLAR

> Bu bölüm Claude, GPT, Gemini, Cursor gibi AI asistanları için yazılmıştır.

### Bağlam
Bu proje, 40 saatlik bir AppJam hackathon kapsamında 3 kişilik bir takım tarafından geliştirilen Flutter mobil uygulamasıdır. Hedef: Türkiye için açık kaynak, ücretsiz deprem hayatta kalma/kurtarma uygulaması.

### Önemli Tasarım İlkeleri (Bunlara Bağlı Kal)
1. **Offline öncelik:** Her özellik internet olmadan çalışmalı. İnternet bağlanırsa "bonus", kaybedilirse "fonksiyon kaybı yok".
2. **Panik dostu UI:** Renk paleti yatıştırıcı (derin yeşil), kırmızı sadece kritik aksiyonda. Büyük dokunma alanları (60dp+). Asla teknik hata mesajı gösterme.
3. **Hibrit AI:** PFA modu **asla LLM'e dokunmaz** — decision tree. Chatbot LLM kullanır ama RAG ile sınırlandırılır. Belirsizlikten kaçınmak için "bilmiyorum" demesini öğret.
4. **Mağdur > Kurtarıcı:** Kurtarıcı modu daha sade. Mağdur modunun her özelliğini kurtarıcıya verme — kurtarıcının AI'ya ihtiyacı yok çünkü eğitimli.
5. **Acımasız önceliklendirme:** 40 saatte her şey bitmez. Tier 1 her zaman, Tier 2 olabildiğince, Tier 3 sadece zaman kalırsa.

### Kod Standartları
- Riverpod 2.x state management
- go_router navigation
- Feature-first folder structure (yukarıda detaylı)
- Türkçe değişken/method adı YASAK — İngilizce. Sadece UI metinleri Türkçe.
- Yorum: WHY, WHAT değil. "// 60 saniye eşiği, kullanıcı tepkisi vermezse otomatik gönderim" — evet. "// timer başlat" — hayır.
- Hata yönetimi: kullanıcıya teknik hata gösterme. Servis hatasını yakala, sessizce retry et veya alternatife yönlendir.

### Geliştirici İçin Ortak Tuzaklar
- **flutter_gemma model dosyası:** `.task` formatında olmalı, doğrudan ggml/gguf çalışmaz. MediaPipe Studio'dan dönüştürülmüş model gerekir.
- **BLE Android 12+:** Yeni permission'lar var (BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE). Manifest'i unutma.
- **iOS background mode:** Info.plist'te "bluetooth-central" ve "bluetooth-peripheral" eklenmeli.
- **AudioPlayers loop:** `ReleaseMode.loop` set edilmeli, yoksa düdük tek seferlik çalar.
- **flutter_map tile caching:** Default cache yetersiz; manual MBTiles veya FileBased tile provider gerekir offline için.

### Senden Beklenen Yardım Türleri
- Spesifik özellik için kod üretme (örn. "SOS akışı için Riverpod controller yaz")
- Bug fix (verilen stack trace ile)
- UI implementasyonu (verilen tasarım için widget kodu)
- Test senaryosu yazma
- Performans optimizasyonu önerme
- Kod review

### Senden Beklenmeyen
- Mimari değiştirme (yukarıdaki kararlar locked)
- Yeni özellik önerme (zaman kısıtı var, kapsam sabit)
- Backend kurma (v1 tamamen client-side)
- Native iOS/Android kodu (Flutter pure-Dart çözümleri tercih edilir)

### Kalite Kontrol
Üretilen herhangi bir kodun:
- Türkiye için Türkçe UI metni içermesi (kullanıcıya görünen)
- Offline çalışması veya bağlantı kontrolüyle düşmesi
- En az bir cihazda gerçekten test edilebilmesi
- Min 60dp dokunma alanı
- Riverpod ile state yönetimi (setState yerine)

gerekir.

---

## 22. EK BİLGİLER

### Lisans
- MIT Lisansı (açık kaynak)
- Üçüncü taraf kütüphaneler kendi lisanslarına tabi
- Gemma 2B: Gemma Terms of Use

### Veri Gizliliği
- Hiçbir veri sunucuya gönderilmez (v1)
- Anonim BLE ID lokalde üretilir, hiçbir yerle ilişkilendirilemez
- Acil kişi telefon numaraları sadece cihazda saklanır
- AI sorguları cihazdan ayrılmaz

### KVKK Uyumu
- v1'de kişisel veri toplamadığımız için KVKK kapsamı dışında
- v2'de kurtarıcı sertifika doğrulamasında VERBİS kaydı gerekebilir

### Hackathon Çıkış Kriteri
Demo sırasında çalışması gereken minimum özellikler:
- [x] Mod seçimi → Mağdur
- [x] SOS butonu → Düdük + 60 sn timer
- [x] Beacon yayını başlar
- [x] İkinci cihazda kurtarıcı → Beacon görünür
- [x] AI chatbot bir soruya cevap verir
- [x] PFA nefes egzersizi animasyonu çalışır
- [x] Toplanma alanı haritası açılır
- [x] Bağış sayfası deeplink açılır

---

**Belge versiyonu:** 1.0
**Son güncelleme:** 2026-05-15
**Hazırlayan:** Kemal + Claude (Anthropic)
**Sonraki adım:** Hackathon başlangıcında Flutter projesini yarat (`flutter create yaninda`), pubspec.yaml'i kopyala, Faz 1'e başla.
