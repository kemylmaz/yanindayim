# Jüri Demosu — Destek Birimi Kayıt Belgesi

Bu doküman, demo sırasında "Destek birimi olarak kayıt ol" akışını jüriye gösterirken kullanacağımız **örnek e-Devlet QR kodlu PDF**'in hazırlanması ve kullanılması için yönergeleri içerir.

## Senaryo

Gerçek uygulamada AKUT, AFAD, Kızılay, AHBAP gibi resmi arama-kurtarma kuruluşlarına bağlı kişiler **e-Devlet** üzerinden "Kurum Personel Belgesi" indirir. Bu PDF üzerinde:

- T.C. kimlik numarası
- Ad / Soyad
- Bağlı olduğu kuruluş
- Sertifika geçerlilik tarihi
- **QR kod** — sorgulama servisine bağlanır

bulunur. Yanındayım uygulaması bu PDF'i yükleyerek QR kodu okur, doğrulama servisine sorgulama yapar ve kimliği yasal yollarla doğrular.

> Hackathon kapsamında: PDF yüklemesi alındığı anda doğrulanmış sayılır (mock). Production'da QR backend sorgulama eklenir.

---

## Demo için örnek PDF hazırlama (2 dakikalık iş)

### Yol 1 — Online araç (en hızlı)

1. https://www.qr-code-generator.com/ adresine git
2. "URL" tipi seç → şu metni yapıştır:
   ```
   https://www.turkiye.gov.tr/akut-personel-sorgulama?belge=DEMO-2026-AKUT-12345
   ```
3. QR kodu **PNG olarak indir**
4. https://www.canva.com/ veya Word'de A4 belge oluştur, şu içeriği kopyala:

```
═══════════════════════════════════════════════════
       TÜRKİYE CUMHURİYETİ
       AFAD — ARAMA KURTARMA PERSONEL BELGESİ
═══════════════════════════════════════════════════

Belge No        : DEMO-2026-AKUT-12345
Düzenleme Tarihi: 16.05.2026
Geçerlilik      : 16.05.2027

─────────────────────────────────────────────────
PERSONEL BİLGİLERİ
─────────────────────────────────────────────────

T.C. Kimlik No  : 1XXXXXXXXX0
Ad Soyad        : KEMAL YILMAZ
Doğum Tarihi    : 01.01.1990
Bağlı Kuruluş   : AKUT Arama Kurtarma Derneği
Görev           : Saha Operatörü
Sertifika Sınıfı: Arama-Kurtarma Seviye 2

─────────────────────────────────────────────────
QR KOD İLE DOĞRULAMA
─────────────────────────────────────────────────

[QR KOD BURAYA GELECEK]

Bu belgenin gerçekliği yandaki QR kod ile
e-Devlet üzerinden sorgulanabilir.

═══════════════════════════════════════════════════
        T.C. AFAD — Resmî Belge
═══════════════════════════════════════════════════
```

5. QR kod görselini belgeye yerleştir
6. **PDF olarak kaydet** → ad: `akut-personel-belgesi-demo.pdf`
7. Bu PDF'i sunum yapacağın telefonun **Downloads** klasörüne yükle

### Yol 2 — Hızlı boş PDF (minimum)

Daha kısa bir yol: Telefonda herhangi bir PDF olsun yeter (uygulama içeriğini doğrulamıyor, sadece dosya seçildi onayı veriyor). Demo sırasında "AKUT belgemi yüklüyorum" diye gösterilen PDF içeriği önemli değil — UI'da seçim onayı görünür.

---

## Demo Akışı

1. **Onboarding** → "Destek Birimi olarak devam et"
2. **Hesap Oluştur** sekmesinde:
   - Ad Soyad: Kemal Yılmaz
   - E-posta: kemal@akut.org
   - Şifre: en az 6 karakter
   - Kuruluş: AKUT
   - Uzmanlık: Arama-Kurtarma
3. **"e-Devlet QR PDF'i yükle"** kartına tıkla → demo PDF'i seç
4. Kart yeşil "Belge yüklendi" durumuna geçer
5. **"Hesap oluştur"** butonuna bas
6. Supabase email doğrulama bağlantısı gönderir (veya direkt giriş olur)
7. **Rescuer ana ekranı (harita)** açılır → mağdur beacon'ları görünür

---

## Doğrulama Mantığı (Hackathon vs Production)

| | Hackathon Demo | Production |
|---|---|---|
| PDF içerik doğrulaması | Yok — sadece dosya seçimi | QR kod okuma + e-Devlet API sorgu |
| Onay süresi | Anlık | 5-30 dakika (manuel inceleme + API) |
| Yetkisiz kişi engelleme | Sadece UI seviye | API tarafı + KVKK uyumlu loglama |
| Belge saklama | Yerel cihazda dosya adı | Supabase Storage, şifreli |

Production tarafı için referans: AFAD Bilgi Sistemleri Daire Başkanlığı yetkilendirme API'leri.
