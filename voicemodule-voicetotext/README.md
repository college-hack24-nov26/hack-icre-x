# 🎙️ JalSanket — Standalone Voice AI & Clinical Triage Module

> **Plug-and-Play Flutter Module** for multilingual voice patient intake, Gemini AI symptom extraction, clinical triage, and offline storage.

---

## 📁 What's Inside This Folder

| File | Purpose |
|------|---------|
| `voice_module.dart` | Single export file. Import this in your app. |
| `voice_screen.dart` | Full interactive Voice Screen with record waves, real-time STT, review fields, doctor consult, and history tab. |
| `voice_engine.dart` | Local clinical rule-based regex extractor, simulated doctor consult generator, and offline SQLite/SharedPreferences store. |
| `gemini_service.dart`| Gemini 1.5/2.5/3.5 Flash AI integration for clinical extraction with offline fallback. |
| `example_main.dart` | Ready-to-run standalone Flutter app wrapper. |
| `pubspec_dependencies.yaml` | Dependencies snippet to copy into your `pubspec.yaml`. |
| `AndroidManifest_snippet.xml` | Required Android permissions (`RECORD_AUDIO`, `INTERNET`, queries). |
| `assets/app-logo.png`| Module logo asset (with graceful fallback if omitted). |

---

## ⚡ Quick Integration (In 3 Simple Steps)

### Step 1: Copy this folder into your Flutter project
Copy `voice_module/` into your target app's `lib/` directory:
```
your_app/
└── lib/
    ├── voice_module/
    │   ├── voice_module.dart
    │   ├── voice_screen.dart
    │   ├── voice_engine.dart
    │   ├── gemini_service.dart
    │   └── assets/
    └── main.dart
```

### Step 2: Add 3 dependencies in `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  speech_to_text: ^7.5.0
  shared_preferences: ^2.5.6
  http: ^1.6.0
```
Then run:
```bash
flutter pub get
```

### Step 3: Add Android Permissions in `AndroidManifest.xml`
In `android/app/src/main/AndroidManifest.xml`, add:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

---

## 🚀 How to Launch in Your App

### Option A: Navigate to Voice Screen from any button
```dart
import 'package:your_app/voice_module/voice_module.dart';

// Inside your onPressed:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const VoiceScreen(
      userName: 'Anita Kulkarni',
      userId: 'A-412',
      userRole: 'ASHA Worker', // or 'Medical Officer'
    ),
  ),
);
```

### Option B: Set as Home Screen
In your `main.dart`:
```dart
import 'package:flutter/material.dart';
import 'voice_module/voice_module.dart';

void main() => runApp(const MaterialApp(
  home: VoiceScreen(),
));
```

### Option C: Build directly into a standalone APK
To build an APK that runs only this voice module directly:
```bash
# Debug run:
flutter run voice_module/example_main.dart

# Build Release APK:
flutter build apk --release -t voice_module/example_main.dart
```

---

## 🌟 Key Features

1. **🌐 Northeast India Multilingual Voice & AI Model Drop Down Menu**:
   - Designed specifically for **ASHA workers, ANMs, PHC Medical Officers, and village users** across Northeast India.
   - Prominent **Dropdown Menu** in the Top Bar and Voice Card for 1-tap language switching.
   - **Supported Languages & Regional Coverage**:
     - 🌾 **Assamese (`অসমীয়া` · `as_IN`)**: Most spoken native language in Northeast India (15M+ speakers), critical *lingua franca* across Assam, Arunachal Pradesh, and Nagaland borders.
     - 🌊 **Bengali (`বাংলা` · `bn_IN`)**: Highest overall numbers across multiple states: Tripura, Assam (Barak Valley), Meghalaya, and Mizoram.
     - 🇮🇳 **Hindi (`हिंदी` · `hi_IN`)**: Inter-state link language across Arunachal Pradesh and urban health centers.
     - 🇬🇧 **English (`English` · `en_IN`)**: Official administrative & health language in Nagaland, Meghalaya, and Mizoram.
     - 🏔️ **Manipuri / Meitei (`মৈতৈলোন্` · `mni_IN`)**: Manipur state official language.
     - 🌿 **Bodo (`बर'` · `brx_IN`)**: Bodoland Territorial Region (BTR, Assam).
     - ⛰️ **Mizo (`Mizo ṭawng` · `lus_IN`)**: Mizoram state official language.
     - 🚩 **Marathi (`मराठी` · `mr_IN`)**: Western India compatibility.
   - **Quick-switch chips** for the top 4 languages (`অসমীয়া`, `বাংলা`, `हिंदी`, `English`) plus full dropdown for all 8 states.
   - Dynamic localized voice hints, example transcripts, danger sign labels, and water contamination triage guidance.

2. **Multilingual Speech-to-Text**:
   - Dynamically binds STT locale to the selected language (`as_IN`, `bn_IN`, `hi_IN`, `en_IN`, `mr_IN`).
   - Built-in live audio pulse waveform animation and speech dictation loop.

3. **Dual-Engine Clinical Extraction**:
   - **Primary Engine**: Google Gemini Flash tailored for Northeast India PHC epidemiology (structured JSON output for symptoms, severity, risk scores, localized risk explanations).
   - **Fallback Engine**: Local rule-based regex parser with Assamese, Bengali, Devanagari, and English numeral normalizers and clinical vocabulary running 100% offline.

4. **Clinical Triage & Doctor Consult**:
   - Evaluates water contamination risk (cholera, hepatitis/jaundice, typhoid, dysentery).
   - Generates recommended treatment plans (ORS, Zinc, boiling protocols, IV referral).
   - Forward cases to doctor queue with priority flags (Urgent / Normal).

5. **Offline Persistence**:
   - Saves all recorded and edited cases locally in `SharedPreferences`.
   - Allows filtering by all cases, danger cases, or doctor-forwarded cases.


---

## ?? Windows Cross-Drive Build Note
If your project is on drive D:\ and Flutter/Pub cache is on C:\, add this to ndroid/gradle.properties:
``properties
kotlin.incremental=false
kotlin.incremental.useClasspathSnapshot=false
``
