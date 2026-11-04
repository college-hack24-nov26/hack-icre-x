# 💧 JalSanket (जल संकेत) — AI-Powered Rural Water Quality & Disease Surveillance Platform

> **Hackathon Submission — Advanced Community Health & Water Surveillance System**  
> *"जल है तो कल है" — Clean Water, Healthy Communities.*

---

## 📌 Project Overview

**JalSanket** (जल संकेत — *Water Signal*) is a cross-platform mobile application and real-time surveillance platform engineered for rural India's frontline health and water management ecosystem.

The system bridges frontline field reporting, clinical tele-triage, real-time IoT water telemetry, and India Meteorological Department (IMD) predictive analytics — replacing paper-based records with an intelligent, offline-resilient, AI-powered surveillance pipeline.

---

## 🚨 Problem Statement

### **Smart Community Health Monitoring and Early Warning System for Water-Borne Diseases in Rural India**

Rural and remote communities across India face recurrent outbreaks of water-borne diseases (cholera, typhoid, acute diarrheal diseases, hepatitis A/E) aggravated by seasonal monsoons, groundwater contamination, and dispersed settlements. Frontline teams face critical operational barriers:

1. **Reporting Latency**: Patient intake is manually collected on paper registers, delaying district epidemic intervention by days or weeks.
2. **Missing Water Telemetry**: Lack of real-time monitoring of turbidity, pH, and TDS at local drinking water sources, hill streams, and piped supply networks.
3. **Siloed Stakeholders**: ASHA workers, Medical Officers, Jalrakshaks, Gram Sevaks (BDO), and District Health Officers (THO) lack a unified live operational picture.
4. **Language & Connectivity Barriers**: Frontline workers require hands-free Marathi and English voice intake that works reliably in remote, low-bandwidth environments.

---

## 💡 Solution Architecture

```
 ┌────────────────────────────────────────────────────────┐
 │                      JalSanket App                     │
 └──────┬───────────────────┬───────────────────┬─────────┘
        │                   │                   │
  [ Frontline ]       [ Tele-Triage ]     [ IoT Telemetry ]
  • ASHA Voice Intake • Doctor Review     • ESP32 Node
  • Gemini AI Extract • Prescriptions     • Live Turbidity/TDS
  • Danger Signs Risk • Clinical Sign-off • BLE / WiFi Sync
        │                   │                   │
 ┌──────┴───────────────────┴───────────────────┴─────────┐
 │               Firebase Realtime Cloud Database         │
 │     /users (Staff RBAC)   •   /voice_cases (Patients)  │
 └──────────────────────────┬─────────────────────────────┘
                            │
              [ IMD Weather & OpenStreetMap ]
              • Live Precipitation & Alerts
              • Potable Water Sources Layer
```

---

## 👥 Role-Based Access Control (RBAC)

JalSanket provides specialized interfaces and workflow restrictions across 6 user roles:

| Role | Designation | Icon | Primary Capabilities |
|------|-------------|------|----------------------|
| **ASHA Worker** | आशा सेविका | 👩‍⚕️ | Voice symptom intake (Marathi/English), AI entity extraction, danger sign scoring, case forwarding to PHC Doctor. |
| **Medical Officer** | वैद्यकीय अधिकारी (MO) | 🩺 | Clinical triage queue of ASHA submissions, diagnosis confirmation, prescription generation, consult sign-off. |
| **THO** | तालुका आरोग्य अधिकारी | 🏥 | Taluka-wide epidemic surveillance, outbreak alert monitoring, PHC performance metrics. |
| **BDO** | गट विकास अधिकारी | 🏛️ | Village infrastructure oversight, Jal Jeevan Mission (JJM) piped water monitoring, administrative reviews. |
| **Jalrakshak** | जलसुरक्षक | 💧 | Local source water testing, bleaching/chlorination dosing calculator, ESP32 sensor calibration. |
| **Citizen** | नागरिक | 👤 | Interactive map of verified potable sources, water issue reporting, symptom intake helpline. |

---

## 🧩 Key System Features

### 🎙️ 1. Multilingual AI Voice Engine
- Hands-free Marathi & English speech-to-text recording.
- Hybrid symptom extractor: Google Gemini 1.5/2.0 Flash AI with regex/keyword offline fallback.
- Automated water-borne disease risk calculation and pediatric/infant danger sign detection.

### 🩺 2. PHC Doctor Triage Queue
- Real-time queue displaying patient cases submitted by frontline ASHA workers.
- Instant pre-populated clinical assessments and treatment plans (ORS, Zinc, Ciprofloxacin, Paracetamol).
- Digital sign-off syncing back to the patient record in the cloud and local storage.

### 📡 3. ESP32 Real-Time IoT Telemetry & ESP Alert
- Live sensor telemetry for Turbidity (NTU), TDS (ppm), and Water Temperature (°C).
- Dynamic dashboard **ESP Alert Banner**:
  - `⚠️ High Turbidity (> 5.0 NTU)`: Immediate contamination warning with dosing prompt.
  - `📡 Node Offline`: Telemetry connectivity alert.
  - `✅ Source Safe & Normal`: Confirmed safe drinking water standards.

### 🚨 4. Patient Count Alert Banner
- Dynamic real-time dashboard banner tracking:
  - Total reported water-borne cases in the jurisdiction.
  - Cases presenting severe danger signs (vomiting, lethargy, dehydration).
  - Number of pending triage cases requiring doctor attention.

### 🗺️ 5. Available Water Sources Map
- Powered by `flutter_map` and OpenStreetMap.
- Filtered to display **100% verified, operational, and safe potable sources**.
- Live indicators for Pimpri Well, Wadi Open Well, Kasba Spring, and public handpumps with TDS, pH, and operational status.

### 🌦️ 6. Live IMD Weather with 1-Tap Refresh
- Automated GPS-matched village weather from Open-Meteo & IMD APIs.
- Real-time rainfall (mm), wind speed (km/h), and temperature (°C).
- Interactive **रिफ्रेश (Refresh)** button with animated loading state.

### ☁️ 7. Firebase Realtime Cloud Integration
- Lightweight REST database endpoints syncing `/users` (staff profiles and designations) and `/voice_cases` (patient transcripts, extracted symptoms, doctor reviews, and prescriptions).

---

## 🛠️ Technology Stack

| Layer | Technologies |
|-------|--------------|
| **Client Framework** | Flutter 3.x / Dart 3.x |
| **AI / NLP** | Google Gemini 1.5/2.0 Flash API + Offline Marathi Regex Engine |
| **Database** | Firebase Realtime Database + SharedPreferences (Offline Cache) |
| **Maps & GIS** | `flutter_map` + `latlong2` + OpenStreetMap Tiles |
| **IoT Hardware** | ESP32 Microcontroller, Analog Turbidity Sensor, TDS Sensor, BLE/WiFi |
| **Weather Telemetry**| India Meteorological Department (IMD) / Open-Meteo Live APIs |
| **Location** | `geolocator` with Village/Block reverse matching |

---

## 📁 Project Directory Skeleton

```
jal-sanket/
├── android/                   # Native Android configuration & manifests
├── assets/                    # Project logos, overlays, and icons
│   └── images/
├── ios/                       # Native iOS build configurations
├── lib/
│   ├── data/                  # Data directory skeleton (raw datasets excluded)
│   ├── screens/               # Role-based UI screens
│   │   ├── dashboard_screen.dart   # Main dashboard with Live Alerts & Weather
│   │   ├── login_screen.dart       # 6-Role authentication & 1-tap quick logins
│   │   ├── map_screen.dart         # Available water sources interactive map
│   │   ├── voice_screen.dart       # ASHA Voice intake & Doctor Triage panel
│   │   ├── test_screen.dart        # IoT telemetry & chlorine dosing calculator
│   │   ├── all_sources_screen.dart # Village water asset registry
│   │   ├── early_signal_screen.dart# Outbreak velocity & rainfall correlation
│   │   └── weekly_report_screen.dart# Automated surveillance report generator
│   ├── services/              # Background & cloud integration services
│   │   ├── esp32_node_service.dart # Real-time IoT sensor telemetry listener
│   │   ├── firebase_service.dart   # Cloud database sync (/users, /voice_cases)
│   │   ├── imd_weather_service.dart# Live IMD meteorological API client
│   │   └── location_detection_service.dart # GPS village matching
│   ├── widgets/               # Reusable UI components & sidebar
│   │   └── app_sidebar.dart        # Role-adaptive navigation drawer
│   └── main.dart              # Application entrypoint
├── pubspec.yaml               # Project dependencies and asset declarations
└── README.md                  # Project documentation
```

---

## 👥 Hackathon Team

| Name | Role | Responsibilities |
|------|------|------------------|
| **Vinayraj Kore** | Lead Full-Stack & Mobile Developer | Flutter app architecture, RBAC, Firebase integration |
| **Sudarshan Lanjile** | Backend & Scraper Engineer | eJalShakti scrapers, IMD weather service |
| **Aditya Desai** | IoT & Hardware Systems Engineer | ESP32 sensor firmware, BLE/HTTP telemetry |
| **Omkar Kamble** | Clinical Research & UI/UX Designer | Frontline health workflow, field testing |

---

## 🚀 Running the Project

```bash
# 1. Clone the repository
git clone https://github.com/college-hack24-nov26/hack-icre-x.git
cd hack-icre-x/jal-sanket-app-source-code

# 2. Get dependencies
flutter pub get

# 3. Verify static analysis
flutter analyze

# 4. Run on a connected Android phone or emulator
flutter run --release
```

---

## 🎯 Sustainable Development Goals (SDG) Alignment

- **SDG 3 — Good Health & Well-Being**: Preempts water-borne disease outbreaks with real-time early warning.
- **SDG 6 — Clean Water & Sanitation**: Continuous water quality monitoring at rural source points.
- **SDG 10 — Reduced Inequalities**: AI-assisted, multilingual clinical tools for rural frontline health workers.
- **SDG 11 — Sustainable Cities & Communities**: Builds climate-resilient water infrastructure in rural areas.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
