# SETUP — Hackathon Hızlı Başlangıç

> Bu dosya Kemal, Emir ve Serhat için hazırlanmıştır. Hackathon başladıktan sonra Faz 1'de 5 dakikada okunup uygulanır.

---

## 1. Şu an elimizde ne var?

Bu klasör (`AppJam_DepremApp/`) içinde **hazır** asset'ler:

```
AppJam_DepremApp/
├── PROJECT.md                              # Tam tasarım belgesi (her şeyin kaynağı)
├── SETUP.md                                # Bu dosya
├── assets/
│   ├── audio/
│   │   └── whistle_3khz.wav                # HAZIR (~860 KB) — 3 sn ses + 2 sn sessizlik, 2 döngü
│   ├── pfa_flow.json                       # HAZIR — 15+ ekran PFA decision tree
│   ├── knowledge_base/
│   │   └── chunks.json                     # HAZIR — 32 chunk Türkçe içerik (embedding'ler boş)
│   └── maps/
│       └── assembly_areas.geojson          # STUB — 25 büyük şehir toplanma alanı (gerçek AFAD verisi ile değiştir)
└── scripts/
    ├── build_knowledge_base.py             # Embedding üretici (Python, run-once)
    └── generate_whistle.ps1                # Düdük yeniden üretici (gerekirse)
```

**Bu kaç saat kazandırdı:** Tahmini **15-20 saat** kolektif zaman tasarrufu.

---

## 2. Flutter Projesini Oluştur (Saat 0, ~15 dakika)

```powershell
# Projeyi oluştur (AppJam_DepremApp/ ile aynı dizinde)
cd "C:\Users\kemyl\OneDrive\Masaüstü\Game Dev"
flutter create yaninda --org com.appjam.yaninda --platforms android,ios
cd yaninda
```

Proje oluştuktan sonra:

```powershell
# Hazır asset'leri Flutter projesine kopyala
xcopy "..\AppJam_DepremApp\assets" "assets\" /E /I /Y
```

**pubspec.yaml**'ı `PROJECT.md` bölüm 15'ten kopyala — bağımlılıklar ve assets bölümleri hazır.

```powershell
flutter pub get
```

---

## 3. Takım Dal Stratejisi (Git)

```powershell
git init
git add .
git commit -m "Initial: Flutter project + AppJam assets"

# Her geliştirici kendi dalında çalışır
git checkout -b kemal/ui
# Emir kendi makinesinde: git checkout -b emir/ble
# Serhat kendi makinesinde: git checkout -b serhat/ai
```

Saat 30 civarında `develop` dalında birleştirme. Saat 36'da `main`'e merge.

---

## 4. Acil Yapılması Gereken Hazırlıklar

Aşağıdakiler Faz 1'de paralel halledilmeli — kimse takılı kalmasın diye sıraya koydum:

### A) Serhat — Lokal AI hazırlığı (Saat 0-4)

**Embedding'leri üret (zorunlu):**
```powershell
cd "C:\Users\kemyl\OneDrive\Masaüstü\Game Dev\AppJam_DepremApp"
pip install sentence-transformers
python scripts/build_knowledge_base.py
```
Bu 30 saniye sürer ve `chunks.json` dosyasını 384 boyutlu embedding'ler ile günceller. Sonra dosyayı Flutter projesinin `assets/knowledge_base/` altına kopyala.

**Gemma 2B modelini indir ve dönüştür:**
1. https://huggingface.co/google/gemma-2b-it adresine git, model ağırlıklarını indir
2. MediaPipe Studio ile `.task` formatına dönüştür: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference#convert_model
3. Veya hazır converted model: https://huggingface.co/litert-community arayışı (gemma-2b INT4)
4. Dönüştürülmüş `.task` dosyasını `assets/ai_model/gemma-2b-it-q4.task` olarak yerleştir
5. Boyut ~1.2 GB — uygulama içine değil, **runtime'da indirilecek** şekilde planla (PROJECT.md bölüm 10)

**Hızlı yol (zaman darsa):** flutter_gemma paketinin example app'inde test modeli vardır, demo için onu kullan.

### B) Emir — BLE permission setup (Saat 0-2)

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Enkaz altındaki kullanıcıları bulmak için Bluetooth kullanıyoruz.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Kurtarıcılara sinyal göndermek için Bluetooth kullanıyoruz.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Konumunuzu acil kişilere göndermek için kullanıyoruz.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Enkaz modunda son konumunuzu kaydetmek için kullanıyoruz.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Sesli komut ile düdüğü kapatabilmek için kullanıyoruz.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Sesli komut tanıma için kullanıyoruz.</string>
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
  <string>bluetooth-peripheral</string>
  <string>audio</string>
  <string>location</string>
</array>
```

### C) Kemal — Tasarım sistemi + ortak widget'lar (Saat 0-6)

Sırayla:
1. `lib/core/theme/colors.dart` — `PROJECT.md` bölüm 9'daki renk paleti
2. `lib/core/theme/typography.dart` — Inter font, sınıflar
3. `lib/core/theme/app_theme.dart` — `ThemeData` birleştirilmiş
4. `lib/features/shared/widgets/big_button.dart` — 60dp+ touch target ortak buton
5. `lib/features/shared/widgets/status_banner.dart` — üst durum şeridi
6. `lib/features/shared/widgets/calm_loader.dart` — yatıştırıcı yükleyici
7. `lib/features/onboarding/mode_selection_screen.dart` — Mağdur / Kurtarıcı seçim

---

## 5. Yapılması Gerekenler — Hâlâ Manuel

| Görev | Sorumlu | Tahmini Süre | Not |
|---|---|---|---|
| Gemma modelini indirip `.task` formatına çevirme | Serhat | 1-2 saat | İnternet + Python gerek |
| AFAD resmi toplanma alanları CSV'sini indirip GeoJSON'a çevirme | Serhat | 30-60 dakika | Mevcut stub yerine kullanılacak |
| Inter font dosyalarını `assets/fonts/`'a indir | Kemal | 5 dakika | fonts.google.com/specimen/Inter |
| NGO logolarını indir (AKUT, Kızılay, AHBAP, İhtiyaç Haritası, AFAD) | Kemal | 15 dakika | Resmi sitelerden, PNG transparent |
| `flutter_gemma` example app'i incele, model yükleme akışını öğren | Serhat | 30 dakika | github.com/DenisovAV/flutter_gemma |
| Test cihazları hazırlığı (en az 2 fiziksel cihaz) | Tüm takım | İlk gün | BLE simulator'de çalışmaz |

---

## 6. Demo İçin Cihaz Hazırlığı

**KRİTİK:** BLE Beacon'u **emulator'da test edemezsiniz**. En az iki gerçek cihaz lazım.

Önerilen demo cihazları:
- **Cihaz 1 (Mağdur):** Android telefon, Android 8+, BLE 4.0+ destekli
- **Cihaz 2 (Kurtarıcı):** iPhone veya Android, aynı şartlar

Demo öncesi son kontrolleri:
- [ ] İki cihazda da uygulama kurulu
- [ ] Gemma modeli iki cihazda da önceden indirilmiş
- [ ] BLE izinleri verilmiş
- [ ] Mağdur cihazda 5 acil kişi numarası girilmiş (test SIM kart önerisi)
- [ ] Kurtarıcı cihazda sertifika numarası girilmiş
- [ ] Toplanma alanı haritası açılıp test edilmiş
- [ ] PFA akışı baştan sona test edilmiş
- [ ] Düdük sesi maksimumda test edilmiş

---

## 7. Demo Sunum Notu

PROJECT.md bölüm 18'de demo senaryosu var. Pitch deck için:
- **Slayt 1:** Problem (Türkiye deprem kuşağında, 2023 sonrası kanıtlanan ihtiyaçlar)
- **Slayt 2:** Çözüm (tek cümle özet)
- **Slayt 3:** Demo videosu (2-3 dakika, ekran kaydı + ses anlatımı)
- **Slayt 4:** Teknik mimari (1 görsel: cihaz - cihaz BLE + offline AI)
- **Slayt 5:** Farklılaşma (rakiplere karşı)
- **Slayt 6:** Takım (Kemal, Emir, Serhat)
- **Slayt 7:** Yol haritası (v1, v2, v3)
- **Slayt 8:** Teşekkür + iletişim

---

## 8. Acil Durum: Demo Çalışmazsa

Eğer demo anında bir özellik çökerse, **yedek plan**:
- BLE çalışmazsa → ekran kaydı (önceden kaydedilmiş) + harita üzerinde "şimdi şu cihaz görünüyor" açıklaması
- AI çalışmazsa → PFA modunu öne çıkar (asla çökmez, çünkü LLM değil)
- Düdük çalmazsa → ses dosyasını harici hoparlörden çal, "telefon hoparlöründen X dB" diyerek anlat
- Harita yüklenmezse → statik resim göster

**ALTIN KURAL:** Demo'da Tier 1 özellikten **biri bile** çökerse derhal yedek plana geç. Jüri hatayı görmesin.

---

## 9. Son Söz

40 saat çok kısa, ama 3 kişi koordineli çalışırsa ve scope disiplinli tutulursa **tam çalışan bir MVP** mümkün. PROJECT.md'deki Tier 1 özellikleri **kesin** çıkmalı, Tier 2 **mümkünse**, Tier 3 **opsiyonel**.

İyi şanslar. Yapacaksınız.

— Hazırlık: 2026-05-15
