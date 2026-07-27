<div align="center">

# YanÄ±ndayÄ±m

### Disaster response that works when the network doesn't.

An offline-first mobile app for the first 72 hours after a major earthquake â€” when base stations are down and every minute counts.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemma](https://img.shields.io/badge/Gemma_on--device-4285F4?style=flat-square&logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Bluetooth LE](https://img.shields.io/badge/BLE-0082FC?style=flat-square&logo=bluetooth&logoColor=white)](https://www.bluetooth.com)
[![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=flat-square&logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)

**Built in 40 hours** Â· EBST Hackathon 2026 Â· BalÄ±kesir University

</div>

---

## The problem

After the February 2023 earthquakes in TÃ¼rkiye, base stations collapsed across eleven provinces. Internet and cellular service went dark exactly when they mattered most.

Survivors trapped under rubble had working phones in their pockets. Rescue teams stood meters away. Neither could reach the other, because every tool they had assumed a connection that no longer existed.

**YanÄ±ndayÄ±m removes that assumption.** Every life-critical feature â€” distress signaling, first-aid guidance, navigation, medical records â€” runs on the device itself. No server. No signal. No internet.

---

## Two roles, one app

The very first screen splits the app into two vertical experiences: **Depremzede** (needs help) and **Destek Birimi** (provides help). Each role gets a purpose-built interface instead of a shared menu with buried options â€” under stress, fewer decisions is better. Role selection is a swipe gesture, not a tap, so it survives cracked screens and shaking hands.

The onboarding screen also states the app's privacy stance up front: *"Verileriniz sadece bu cihazda kalÄ±r"* â€” your data stays on this device.

<div align="center">

| Role selection | SOS + live beacon | On-device AI assistant |
|:---:|:---:|:---:|
| <img src="screenshots/onboarding.png" width="240"/> | <img src="screenshots/sos.png" width="240"/> | <img src="screenshots/ai-assistant.png" width="240"/> |

| AFAD assembly areas | Emergency health card | Family check-in |
|:---:|:---:|:---:|
| <img src="screenshots/assembly-map.jpg" width="240"/> | <img src="screenshots/health-card.png" width="240"/> | <img src="screenshots/checkin.png" width="240"/> |

| Donation routing | Safety settings |
|:---:|:---:|
| <img src="screenshots/donation.png" width="240"/> | <img src="screenshots/settings.png" width="240"/> |

</div>

---

## Features

### ğŸ”µ BLE peer-to-peer distress beacon

The core of the app. A trapped victim's phone advertises a Bluetooth Low Energy beacon carrying a compact distress payload under an **anonymous ID** â€” no name, no account, nothing that identifies the person to a stranger scanning the air. Any responder's phone within range picks it up and surfaces proximity and signal strength.

No internet. No base station. No pairing handshake. Two phones and a radio that draws almost no power.

- `flutter_ble_peripheral` â€” advertising on the victim side
- `flutter_blue_plus` â€” scanning on the responder side
- `ble_constants.dart` â€” shared payload protocol between the two
- `flutter_background_service` â€” keeps the beacon alive with the screen off, which matters when a phone has to last three days on one charge

### ğŸ“± AR beacon scanning

Camera feed plus magnetometer compass (`camera` + `flutter_compass`). A responder points the phone at the rubble and sees the **bearing of nearby distress signals overlaid live** on the camera view. Signal strength narrows the distance; the compass gives the direction. Together they turn "somebody is within 30 meters" into "somebody is that way."

### ğŸ¤– On-device LLM assistant (Gemma + RAG)

Gemma runs **locally on the phone** via `flutter_gemma` (MediaPipe), grounded by retrieval over a disaster-guidance knowledge base bundled into the app (`assets/knowledge_base/chunks.json`).

It answers the questions people actually ask in the first hours â€” *I'm under rubble. How do I stop bleeding. Aftershock safety. How to find water. How to save battery* â€” with the radio switched off entirely. Because generation is grounded in a vetted, fixed corpus rather than open-ended, the assistant cannot improvise dangerous medical advice.

Voice input via `speech_to_text` covers anyone who can speak but cannot reach or see their screen.

### ğŸš¨ SOS with lock-screen bypass and cellular fallback

One button starts everything: beacon broadcasting, the audible whistle, and location capture.

`wakelock_plus` keeps the screen alive, and while SOS is active the **health card is visible without unlocking the phone** â€” so a responder who finds an unconscious person gets blood type and allergies immediately, without a PIN they will never have.

Where any cellular channel still survives, SMS and 112 intents fire in parallel via `url_launcher`. SMS frequently gets through in conditions that kill data connections, so it is treated as a first-class path rather than a fallback afterthought.

### ğŸ“¢ Audible whistle beacon

Looping audio playback tuned to the **Fox 40 / AFAD standard: 2.7â€“3.3 kHz dual-tone**. That frequency band is chosen deliberately â€” it carries through concrete and debris better than a human voice, and it is the tone rescue teams are trained to listen for. For the last few meters, sound beats every radio.

### ğŸ“‰ Stillness and impact detection

Accelerometer monitoring via `sensors_plus` for earthquake onset and prolonged immobility â€” the signal that someone has stopped moving and may need escalation.

### ğŸ—ºï¸ Offline maps and AFAD assembly points

`flutter_map` over locally cached OpenStreetMap tiles, layered with official AFAD assembly-area data. Selecting a site shows **walking distance, estimated time on foot, capacity, and on-site facilities** (water, sanitation) â€” with routing computed offline. In the screenshot: Karesi Ã‡amlÄ±k ParkÄ±, 15.9 km northwest, ~3 h 12 min on foot, capacity ~8,000.

### ğŸ¥ QR emergency health card

Blood type, allergies, chronic conditions, and current medications rendered as a QR code via `qr_flutter`. A paramedic who has never met the patient scans it and has the medical picture in seconds â€” no internet, no records lookup, no conscious patient required.

### âœ… "I'm safe" family check-in

Pick contacts straight from the phonebook (`flutter_contacts`), choose a pre-written message â€” *GÃ¼vendeyim* / *YardÄ±m lazÄ±m* / *BuluÅŸma noktasÄ±na gidiyorum* â€” and send via WhatsApp or SMS in one tap. Pre-written matters: typing is the first thing that fails when hands shake.

### ğŸ¤ Direct donation routing

Links straight to AKUT, KÄ±zÄ±lay, AHBAP, Ä°htiyaÃ§ HaritasÄ±, AFAD, and TEMA. The app **never handles money and never sits between donor and organization** â€” every link goes to the institution's own page. A deliberate trust decision: disaster fundraising attracts fraud, and the safest architecture is one where we cannot touch the funds.

---

## Architecture

```mermaid
flowchart TB
    subgraph OFF["âš¡ Offline â€” the baseline"]
        direction LR
        V["ğŸ“± Victim<br/>BLE advertise Â· whistle Â· SOS"] -.->|BLE anonymous ID| R["ğŸ’ Responder<br/>BLE scan Â· AR compass"]
        LLM[("ğŸ¤– Gemma on-device<br/>+ RAG knowledge base")]
        MAP[("ğŸ—ºï¸ Cached OSM tiles<br/>+ AFAD assembly data")]
        HIVE[("ğŸ’¾ Hive local storage<br/>health card Â· contacts")]
    end

    subgraph ON["â˜ï¸ Online â€” the bonus"]
        SB[("Supabase<br/>auth Â· database Â· realtime")]
    end

    V --> LLM
    V --> MAP
    V --> HIVE
    V -->|SMS / 112 intent| CELL["ğŸ“¡ Cellular fallback"]
    V -.->|when connectivity returns| SB
    R -.->|when connectivity returns| SB

    style OFF fill:#0d3b2e,stroke:#3FCF8E,color:#fff
    style ON fill:#14213d,stroke:#4a7fd4,color:#fff
```

The principle throughout: **offline is the baseline, online is the bonus.** Supabase handles authentication, persistence, and realtime coordination when a connection exists â€” but nothing life-critical waits on it. Pull the SIM card and the app still signals, still advises, still navigates.

---

## Tech stack

| Layer | Package | Why this choice |
|---|---|---|
| Framework | Flutter / Dart | One codebase across Android and iOS |
| State & routing | `flutter_riverpod`, `go_router` | Predictable state across two distinct role flows |
| On-device LLM | `flutter_gemma` | Inference with zero network dependency |
| BLE advertise | `flutter_ble_peripheral` | Victim-side broadcasting |
| BLE scan | `flutter_blue_plus` | Responder-side detection |
| Background execution | `flutter_background_service`, `wakelock_plus` | Beacon survives screen-off; SOS survives lock |
| Mapping | `flutter_map`, `latlong2`, `geolocator` | Tiles cache locally; no proprietary SDK lock-in |
| AR direction finding | `camera`, `flutter_compass` | Bearing overlay on live camera |
| Sensors | `sensors_plus` | Impact and stillness detection |
| Audio | `audioplayers` | Looping whistle beacon |
| Voice | `speech_to_text` | Turkish hands-free input |
| Local storage | `hive`, `shared_preferences` | Health card and contacts persist on-device |
| Health card | `qr_flutter` | Offline-readable by any camera |
| Contacts | `flutter_contacts` | Check-in recipient selection |
| Backend (online only) | `supabase_flutter` | Auth, database, realtime sync |

---

## Project structure

```
lib/
â”œâ”€â”€ core/
â”‚   â””â”€â”€ services/
â”‚       â”œâ”€â”€ beacon_broadcast_service.dart   # BLE advertising â€” victim side
â”‚       â”œâ”€â”€ beacon_scanner_service.dart     # BLE scanning â€” responder side
â”‚       â””â”€â”€ ble_constants.dart              # Shared payload protocol
â””â”€â”€ features/
    â”œâ”€â”€ victim/
    â”‚   â”œâ”€â”€ checkin/        # "I'm safe" family notification
    â”‚   â”œâ”€â”€ health/         # QR emergency health card
    â”‚   â”œâ”€â”€ map/            # Offline map + AFAD assembly areas
    â”‚   â”œâ”€â”€ chat/           # On-device Gemma assistant
    â”‚   â””â”€â”€ pfa/            # Psychological first aid flow
    â”œâ”€â”€ rescuer/
    â”‚   â””â”€â”€ home/           # Beacon scanner and victim prioritization
    â””â”€â”€ settings/           # Role switching, safety feature toggles

assets/
â”œâ”€â”€ knowledge_base/         # RAG corpus (chunks.json)
â”œâ”€â”€ maps/                   # Cached offline tiles
â”œâ”€â”€ audio/                  # Whistle beacon
â”œâ”€â”€ pfa_flow.json           # Psychological first aid decision tree
â””â”€â”€ icon/                   # App icon source
```

Feature-first architecture: each role owns a vertical slice, shared infrastructure isolated in `core/`.

---

## Permissions and why each is needed

Emergency apps ask for a lot. Here is the honest accounting:

| Permission | Purpose |
|---|---|
| `BLUETOOTH_ADVERTISE` / `SCAN` / `CONNECT` | The peer-to-peer distress beacon â€” the app's core function |
| `ACCESS_FINE_LOCATION` + `BACKGROUND_LOCATION` | SMS payload coordinates and offline map positioning |
| `FOREGROUND_SERVICE` + `WAKE_LOCK` | Beacon and SOS survive screen-off and lock |
| `SEND_SMS` / `CALL_PHONE` | Cellular fallback path to 112 and family |
| `RECORD_AUDIO` | Voice commands and stopping the whistle hands-free |
| `READ_CONTACTS` | Selecting check-in recipients |
| `CAMERA` | AR beacon direction finding |
| `INTERNET` | **Model download only** â€” no runtime dependency |

---

## Getting started

```bash
git clone https://github.com/kemylmaz/yanindayim.git
cd yanindayim
flutter pub get
flutter run
```

**Notes for a full run:**

- The Gemma model file is not committed (size constraints). It is fetched on first launch or must be supplied separately.
- Supabase credentials are not committed. Supply your own project URL and anon key to enable online features.
- BLE advertising, AR compass, and sensor features require a **physical device** â€” emulators do not expose these radios.

---

## Status and roadmap

Built under hackathon conditions in 40 hours. Core flows are functional; below are the honest next steps.

- [ ] **Multi-hop BLE mesh** â€” relay distress signals across intermediate devices, extending effective range far beyond line of sight
- [ ] **Responder verification** via e-Devlet QR PDF certificates, to keep unverified actors out of the responder network
- [ ] **Battery-optimized background scanning** for genuine multi-day operation
- [ ] **AFAD / KÄ±zÄ±lay dispatch integration** â€” a formal data path into official coordination systems
- [ ] **Expanded knowledge base** with a broader vetted disaster corpus
- [ ] **Other disaster types** â€” floods, wildfires, industrial accidents

---

## Design notes

A few decisions worth stating, because they were deliberate rather than accidental:

**Green, not red.** Emergency apps default to red alarm palettes. Red raises heart rate â€” the opposite of what someone under rubble needs. The interface is calm green; red appears only on the SOS button itself, where urgency is the point.

**Reassurance before instruction.** The home screen opens with *"Åu an gÃ¼vendesin"* â€” you are safe right now â€” before showing any control. Panic degrades decision-making more than missing information does.

**Swipe to choose a role, not tap.** A larger gesture target for shaking hands and damaged screens.

**Pre-written messages.** Every outgoing communication is one tap on a prepared template. Nothing life-critical requires typing.

---

## Team

| | Role |
|---|---|
| **Kemal YÄ±lmaz** â€” [@kemylmaz](https://github.com/kemylmaz) | Product concept, target audience, business model, pitch |
| **Serhat** â€” [@username](https://github.com/) | Development |

---

## TÃ¼rkÃ§e

**YanÄ±ndayÄ±m**, bÃ¼yÃ¼k bir deprem sonrasÄ± ilk 72 saat iÃ§in tasarlanmÄ±ÅŸ, internet baÄŸlantÄ±sÄ± olmadan Ã§alÄ±ÅŸan bir afet mÃ¼dahale uygulamasÄ±dÄ±r.

Åubat 2023 depremlerinde baz istasyonlarÄ± on bir ilde Ã§Ã¶ktÃ¼ ve tam da en Ã§ok ihtiyaÃ§ duyulan anda iletiÅŸim tamamen kesildi. YanÄ±ndayÄ±m bu varsayÄ±mÄ± ortadan kaldÄ±rÄ±r: hayati her Ã¶zellik cihazÄ±n kendisinde Ã§alÄ±ÅŸÄ±r.

**Ã–ne Ã§Ä±kan Ã¶zellikler:**

- **BLE eÅŸler arasÄ± yardÄ±m sinyali** â€” enkaz altÄ±ndaki kiÅŸinin telefonu anonim bir ID ile Bluetooth sinyali yayÄ±nlar, yakÄ±ndaki destek birimlerinin telefonlarÄ± bunu internetsiz yakalar
- **AR beacon tarama** â€” kamera ve pusula ile sinyalin yÃ¶nÃ¼ canlÄ± olarak ekranda gÃ¶sterilir
- **Cihazda Ã§alÄ±ÅŸan yapay zekÃ¢** â€” Gemma modeli telefonda yerel olarak Ã§alÄ±ÅŸÄ±r, uygulamaya gÃ¶mÃ¼lÃ¼ afet bilgi tabanÄ±ndan cevap Ã¼retir; internet gerekmez, uydurma tÄ±bbi tavsiye vermez
- **Kilit ekranÄ± bypass** â€” SOS aktifken saÄŸlÄ±k kartÄ± telefon aÃ§Ä±lmadan gÃ¶rÃ¼nÃ¼r
- **Acil durum dÃ¼dÃ¼ÄŸÃ¼** â€” Fox 40 / AFAD standardÄ±nda 2.7â€“3.3 kHz Ã§ift tonlu ses
- **Ã‡evrimdÄ±ÅŸÄ± harita ve AFAD toplanma alanlarÄ±** â€” yÃ¼rÃ¼me mesafesi, sÃ¼re, kapasite ve olanaklar dahil
- **QR kodlu acil saÄŸlÄ±k kartÄ±** â€” kan grubu, alerjiler, ilaÃ§lar saniyeler iÃ§inde okunur
- **GÃ¼vendeyim bildirimi** â€” rehberden seÃ§ilen kiÅŸilere hazÄ±r mesajla tek tÄ±kla haber verme
- **BaÄŸÄ±ÅŸ yÃ¶nlendirme** â€” AKUT, KÄ±zÄ±lay, AHBAP, Ä°htiyaÃ§ HaritasÄ±, AFAD ve TEMA'nÄ±n kendi sayfalarÄ±na doÄŸrudan yÃ¶nlendirme; uygulama para akÄ±ÅŸÄ±na hiÃ§bir noktada dahil olmaz

Flutter ile, EBST Hackathon 2026 kapsamÄ±nda 40 saatte geliÅŸtirildi.

---

<div align="center">

**Ã‡Ã¼nkÃ¼ her saniye bir hayattÄ±r.**

</div>
