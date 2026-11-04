# 💧 JalSanket — AI-Powered Rural Water Quality & Health Surveillance

> **Hackathon Project — Initial Submission**  
> *"जल है तो कल है" — If there is water, there is a future.*

---

## 📌 Project Overview

**JalSanket** (जल संकेत — *Water Signal*) is a cross-platform mobile application designed for rural India's frontline health workers (ASHA workers, ANMs, PHC officers).

The app bridges the gap between **water quality monitoring**, **disease early-warning**, and **Jal Jeevan Mission government data** — putting AI-powered tools directly in the hands of village-level workers who currently operate with pen and paper.

---

## 🚨 Problem Statement

### **Smart Community Health Monitoring and Early Warning System for Water-Borne Diseases in Rural Northeast India**

Rural and remote communities across Northeast India face acute vulnerabilities to water-borne diseases (cholera, typhoid, acute diarrheal diseases, dysentery) aggravated by heavy seasonal monsoons, frequent flash floods, hilly topography, and scattered village settlements. Frontline community health workers (ASHA workers, ANMs) face critical bottlenecks:

- Collect health and patient intake data **manually on paper registers**, leading to reporting delays of days or weeks before district health teams can intervene
- Lack **real-time water quality telemetry** at local drinking water sources, hill streams, and piped supply points
- Cannot **predict or preempt outbreaks** before case velocity turns into a widespread community epidemic
- Navigate **geographical isolation and multilingual/connectivity barriers**, needing voice-enabled, offline-first digital decision support

---

## 💡 Proposed Solution

A Flutter-based app with:

- 🎙️ **Multilingual voice input** (Marathi + English) for hands-free patient case recording
- 🤖 **Gemini AI** for intelligent symptom extraction from voice transcripts
- 📡 **IoT sensor integration** (ESP32 nodes) for real-time water quality telemetry
- 🗺️ **Interactive map** showing water sources, case clusters, and risk zones
- ☁️ **IMD weather integration** for rainfall-driven outbreak prediction
- 🔗 **Jal Jeevan Mission (JJM) data** pulled from the eJalShakti portal

---

## 🧩 Planned Features

- [ ] Login & role-based access (ASHA Worker / Medical Officer / Admin)
- [ ] Dashboard with live weather, pending cases, and trend charts
- [ ] Voice-based patient case recorder with AI field extraction
- [ ] Early signal detection (rainfall + case velocity risk scoring)
- [ ] What-If SIR epidemic simulator
- [ ] ESP32 BLE water sensor node telemetry viewer
- [ ] Interactive village map (flutter_map + OpenStreetMap)
- [ ] JJM eJalShakti village portal integration
- [ ] QR code scanner for water source identification
- [ ] Weekly auto-generated health reports
- [ ] Responsible AI transparency panel

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x / Dart 3.x |
| **AI Engine** | Google Gemini 1.5 Flash |
| **Maps** | `flutter_map` + OpenStreetMap |
| **Voice** | `speech_to_text` (Marathi + English) |
| **IoT** | ESP32 via BLE |
| **Weather** | India Meteorological Department (IMD) API |
| **Gov Data** | eJalShakti JJM Portal |
| **Location** | `geolocator` |
| **Storage** | `shared_preferences` |

---

## 👥 Team

| Name | Role |
|------|------|
| **Vinayraj Kore** | Frontend Developer |
| **Sudarshan Lanjile** | Backend Developer |
| **Aditya Desai** | IoT Engineer |
| **Omkar Kamble** | Research & UI/UX |

---

## 🚀 Getting Started

```bash
# Clone the repo
git clone https://github.com/college-hack24-nov26/hack-icre-x.git
cd hack-icre-x

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> **Note:** A Gemini API key is optional. The app runs in rule-based regex fallback mode without it.  
> Get a free key at [ai.google.dev](https://ai.google.dev)

---

## 📁 Project Structure *(in progress)*

```
jal-sanket/
├── lib/
│   ├── main.dart
│   ├── screens/       # UI screens
│   ├── services/      # API & BLE services
│   └── widgets/       # Reusable components
├── assets/
│   └── images/
└── pubspec.yaml
```

---

## 🎯 SDG Alignment

| SDG | Relevance |
|-----|-----------|
| **SDG 3** — Good Health & Well-Being | Early outbreak detection reduces disease burden |
| **SDG 6** — Clean Water & Sanitation | Real-time IoT water quality monitoring |
| **SDG 10** — Reduced Inequalities | AI tools for rural frontline workers | 

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

*This README will be updated as the project progresses during the hackathon.*
