# Firebase Realtime Database schema

Jal Sanket uses Firebase Realtime Database (RTDB) for ESP32 water-monitoring data. Unlike SQL, RTDB does not enforce a database schema: its JSON tree and security rules define the effective data model. This directory contains both.

- `database.example.json` is a safe, empty-state JSON tree for a new RTDB instance.
- `database.rules.json` is a role-based security-rules template.
- `../firebase.json` tells the Firebase CLI where the rules file is.

## Current ESP32-compatible paths

These paths match `lib/services/esp32_node_service.dart` exactly; keep their uppercase names when setting up the existing ESP32 firmware and Flutter client.

```text
/
├── SENSOR_DATA                 # latest ESP32 telemetry (not historical)
│   ├── Heartbeat                # epoch milliseconds or device uptime
│   ├── UptimeSec
│   ├── Temperature              # °C; -127/85 are hardware error values
│   ├── TDS                      # ppm
│   ├── TurbidityVoltage          # volts
│   └── TurbidityNTU_Estimate
├── TEST_STATUS                  # current testing state
├── TEST_COMMAND                 # latest START or STOP command for ESP32
├── TEST_RESULTS/{testId}        # completed water-test history, e.g. T1793620278
├── CHLORINATION_STATUS          # current pump state
├── CHLORINATION_COMMAND         # latest START or EMERGENCY_STOP command
├── DEVICE_COMMAND/{pushId}      # compatibility command queue
├── CONFIG                       # tdsMax, turbidityMax, maxDoseMl
├── SCHEDULE                     # enabled, time (HH:MM)
└── SCHEDULE_STATE               # last executed automated test
```

The root `SENSOR_DATA` is intentionally only the latest reading. If you need durable historical telemetry, add a Cloud Function or device gateway that copies periodic readings to `telemetry/{nodeId}/{timestamp}`. Do not append an unbounded stream under `SENSOR_DATA`.

## App-data paths

The following is the Firebase-shaped equivalent of the relational model in `../database/schema.sql`. It is not wired into the Flutter app yet, which currently keeps this data in `SharedPreferences`.

```text
userProfiles/{uid}                         # displayName, role, operatorCode, defaultVillageId
villages/{villageId}                       # name, district, block, coordinates, JJM IDs
waterSources/{sourceId}                    # villageId, name, type, status, riskScore
iotNodes/{nodeId}                          # nodeCode, waterSourceId, firmware, lastSeenAt
patients/{patientId}                       # pseudoId, displayName, homeVillageId
patientCases/{caseId}                      # clinical case, transcript, risk fields, symptoms
caseIndexByVillage/{villageId}/{caseId}    # denormalized query index: { recordedAt, severityFlag }
clinicalNotes/{caseId}/{noteId}            # signed medical-officer consultation notes
fieldTasks/{taskId}                        # operational tasks and completion state
weatherReports/{villageId}/{reportId}      # cached IMD report and forecast
earlyRiskAssessments/{villageId}/{id}      # forecast-based water-health risk
jjmVillageSnapshots/{villageId}/{id}       # scraped Jal Jeevan Mission data
```

Use generated Firebase push IDs or UUIDs for mutable records. When a screen needs records by a different field, store a small denormalized index (such as `caseIndexByVillage`) instead of downloading every case and filtering on-device.

## Deploy rules

1. Install the Firebase CLI and authenticate: `firebase login`.
2. Select your Firebase project: `firebase use --add`.
3. Review the role names and validation rules in `database.rules.json`.
4. Deploy only Realtime Database rules: `firebase deploy --only database`.

The rules require Firebase Authentication and a custom `role` claim with one of: `device`, `asha_worker`, `medical_officer`, `gram_sevak`, `water_operator`, or `admin`. The current Flutter service sends unauthenticated REST requests, so it will be denied after these rules are deployed until Firebase Auth ID tokens are added to those requests or writes are routed through a trusted server/Cloud Function. Do not use public read/write rules for clinical or device-control data.

Firebase RTDB Security Rules govern access and validation; Firebase documents that rules can use `auth` and custom claims in `auth.token`, and that `firebase.json` can deploy RTDB rules through the CLI. [Rules conditions](https://firebase.google.com/docs/database/security/rules-conditions) and [Firebase CLI deployment](https://firebase.google.com/docs/cli) provide the implementation reference.
