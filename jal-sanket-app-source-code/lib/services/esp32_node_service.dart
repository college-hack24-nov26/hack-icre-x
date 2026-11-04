import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Models for ESP32 Sensor Node & Jal Sanket IoT Ecosystem

enum NodeConnectionState {
  offline,
  verifying,
  online,
}

class SensorData {
  final double? temperature;
  final bool temperatureConnected;
  final String temperatureStatus;
  final double? temperatureLastKnown;

  final double? tds;
  final bool tdsConnected;
  final String tdsStatus;
  final double? tdsVoltage;
  final int? tdsRawAdc;
  final double? tdsSpread;
  final double? tdsLastKnown;

  final double? turbidityVoltage;
  final double? turbidityNTU;
  final bool turbidityConnected;
  final String turbidityStatus;
  final int? turbidityRawAdc;
  final double? turbiditySpread;
  final double? turbidityLastKnown;

  final int heartbeat;
  final int? uptimeSec;
  final DateTime receivedAt;

  SensorData({
    this.temperature,
    this.temperatureConnected = false,
    this.temperatureStatus = 'OFFLINE',
    this.temperatureLastKnown,
    this.tds,
    this.tdsConnected = false,
    this.tdsStatus = 'OFFLINE',
    this.tdsVoltage,
    this.tdsRawAdc,
    this.tdsSpread,
    this.tdsLastKnown,
    this.turbidityVoltage,
    this.turbidityNTU,
    this.turbidityConnected = false,
    this.turbidityStatus = 'OFFLINE',
    this.turbidityRawAdc,
    this.turbiditySpread,
    this.turbidityLastKnown,
    this.heartbeat = 0,
    this.uptimeSec,
    required this.receivedAt,
  });

  bool get isTempValid =>
      temperature != null &&
      temperature != -127 &&
      temperature != 85 &&
      !temperature!.isNaN;

  bool get isTempLive =>
      isTempValid && temperatureConnected && temperatureStatus != 'ERROR';

  bool get isTdsLive => tdsConnected && tds != null && !tds!.isNaN;

  bool get isTurbidityLive =>
      turbidityConnected &&
      turbidityVoltage != null &&
      !turbidityVoltage!.isNaN;

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // Temperature parsing
    double? temp = _parseDouble(json['Temperature']);
    double? tempLast = _parseDouble(json['TemperatureLastKnown']);
    bool tempConn = json['TemperatureConnected'] == true;
    String tempStat = json['TemperatureStatus']?.toString() ?? 'LIVE';
    if (temp != null && (temp == -127 || temp == 85)) {
      tempConn = false;
      tempStat = 'ERROR';
    } else if (temp != null && !tempConn && tempStat == 'LIVE') {
      tempConn = true;
    }

    // TDS parsing
    double? tdsVal = _parseDouble(json['TDS']);
    double? tdsLast = _parseDouble(json['TDSLastKnown']);
    double? tdsVolt = _parseDouble(json['TDSVoltage']);
    int? tdsRaw = _parseInt(json['TDSRawADC']);
    double? tdsSpr = _parseDouble(json['TDSSpread']);
    bool tdsConn = json['TDSConnected'] == true;
    String tdsStat = json['TDSStatus']?.toString() ?? 'LIVE';
    if (json['TDSConnected'] == null) {
      // Automatic detection: if tdsVal is non-null and valid voltage
      tdsConn = tdsVal != null && (tdsVolt == null || (tdsVolt >= 0.04 && tdsVolt <= 3.20));
    }

    // Turbidity parsing
    double? turbVolt = _parseDouble(json['TurbidityVoltage'] ?? json['Turbidity']);
    double? turbNtu = _parseDouble(json['TurbidityNTU_Estimate']);
    double? turbLast = _parseDouble(json['TurbidityLastKnown']);
    int? turbRaw = _parseInt(json['TurbidityRawADC']);
    double? turbSpr = _parseDouble(json['TurbiditySpread']);
    bool turbConn = json['TurbidityConnected'] == true;
    String turbStat = json['TurbidityStatus']?.toString() ?? 'LIVE';
    if (json['TurbidityConnected'] == null) {
      turbConn = turbVolt != null && turbVolt > 0.1 && turbVolt < 4.8;
    }

    int hb = _parseInt(json['Heartbeat']) ?? 0;
    int? uptime = _parseInt(json['UptimeSec']);

    return SensorData(
      temperature: temp,
      temperatureConnected: tempConn,
      temperatureStatus: tempStat,
      temperatureLastKnown: tempLast ?? temp,
      tds: tdsVal,
      tdsConnected: tdsConn,
      tdsStatus: tdsStat,
      tdsVoltage: tdsVolt,
      tdsRawAdc: tdsRaw,
      tdsSpread: tdsSpr,
      tdsLastKnown: tdsLast ?? tdsVal,
      turbidityVoltage: turbVolt,
      turbidityNTU: turbNtu,
      turbidityConnected: turbConn,
      turbidityStatus: turbStat,
      turbidityRawAdc: turbRaw,
      turbiditySpread: turbSpr,
      turbidityLastKnown: turbLast ?? turbVolt,
      heartbeat: hb,
      uptimeSec: uptime,
      receivedAt: DateTime.now(),
    );
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }
}

class TestStatus {
  final String state; // IDLE, RUNNING, COMPLETED, STOPPED
  final String? testId;
  final String? mode;
  final String? message;
  final int? startMs;
  final int? endMs;

  TestStatus({
    this.state = 'IDLE',
    this.testId,
    this.mode,
    this.message = 'Idle and ready',
    this.startMs,
    this.endMs,
  });

  factory TestStatus.fromJson(Map<String, dynamic> json) {
    return TestStatus(
      state: json['state']?.toString() ?? 'IDLE',
      testId: json['testId']?.toString(),
      mode: json['mode']?.toString(),
      message: json['message']?.toString(),
      startMs: json['startMs'] is num ? (json['startMs'] as num).toInt() : null,
      endMs: json['endMs'] is num ? (json['endMs'] as num).toInt() : null,
    );
  }
}

class ChlorinationStatus {
  final String state; // STANDBY, SIMULATION_RUNNING, SIMULATION_COMPLETED, ERROR
  final double? doseMl;
  final String? testId;
  final String? message;
  final int? progress;

  ChlorinationStatus({
    this.state = 'STANDBY',
    this.doseMl,
    this.testId,
    this.message = 'Pump idle and ready',
    this.progress = 0,
  });

  factory ChlorinationStatus.fromJson(Map<String, dynamic> json) {
    return ChlorinationStatus(
      state: json['state']?.toString() ?? 'STANDBY',
      doseMl: json['doseMl'] is num ? (json['doseMl'] as num).toDouble() : null,
      testId: json['testId']?.toString(),
      message: json['message']?.toString(),
      progress: json['progress'] is num ? (json['progress'] as num).toInt() : 0,
    );
  }
}

class SystemConfig {
  final double tdsMax;
  final double turbidityMax;
  final double maxDoseMl;

  SystemConfig({
    this.tdsMax = 500.0,
    this.turbidityMax = 5.0,
    this.maxDoseMl = 50.0,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      tdsMax: (json['tdsMax'] is num) ? (json['tdsMax'] as num).toDouble() : 500.0,
      turbidityMax: (json['turbidityMax'] is num) ? (json['turbidityMax'] as num).toDouble() : 5.0,
      maxDoseMl: (json['maxDoseMl'] is num) ? (json['maxDoseMl'] as num).toDouble() : 50.0,
    );
  }
}

class ScheduleConfig {
  final bool enabled;
  final String time; // "HH:MM" 24h format

  ScheduleConfig({
    this.enabled = false,
    this.time = '08:00',
  });

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      enabled: json['enabled'] == true,
      time: json['time']?.toString() ?? '08:00',
    );
  }
}

class ScheduleState {
  final String? lastRunDate;
  final String? lastRunTime;
  final String? status;

  ScheduleState({this.lastRunDate, this.lastRunTime, this.status});

  factory ScheduleState.fromJson(Map<String, dynamic> json) {
    return ScheduleState(
      lastRunDate: json['lastRunDate']?.toString(),
      lastRunTime: json['lastRunTime']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class WaterTestRecord {
  final String testId;
  final int? startMs;
  final int? endMs;
  final double tds;
  final double turbidity;
  final double temperature;
  final String mode;
  final String waterStatus;
  final bool chlorinationRequired;
  final String chlorinationStatus;

  WaterTestRecord({
    required this.testId,
    this.startMs,
    this.endMs,
    required this.tds,
    required this.turbidity,
    required this.temperature,
    required this.mode,
    required this.waterStatus,
    required this.chlorinationRequired,
    required this.chlorinationStatus,
  });

  factory WaterTestRecord.fromJson(String id, Map<String, dynamic> json) {
    return WaterTestRecord(
      testId: json['testId']?.toString() ?? id,
      startMs: json['startMs'] is num ? (json['startMs'] as num).toInt() : null,
      endMs: json['endMs'] is num ? (json['endMs'] as num).toInt() : null,
      tds: (json['TDS'] is num) ? (json['TDS'] as num).toDouble() : 0.0,
      turbidity: (json['Turbidity'] is num) ? (json['Turbidity'] as num).toDouble() : 0.0,
      temperature: (json['Temperature'] is num) ? (json['Temperature'] as num).toDouble() : 25.0,
      mode: json['mode']?.toString() ?? 'Manual',
      waterStatus: json['waterStatus']?.toString() ?? 'Within criteria',
      chlorinationRequired: json['chlorinationRequired'] == true,
      chlorinationStatus: json['chlorinationStatus']?.toString() ?? 'Not Required',
    );
  }
}

class TelemetryPoint {
  final DateTime timestamp;
  final double? tds;
  final double? turbidity;
  final double? temperature;

  TelemetryPoint({
    required this.timestamp,
    this.tds,
    this.turbidity,
    this.temperature,
  });
}

/// Service connecting directly to Firebase RTDB for ESP32 IoT Node
class Esp32NodeService {
  static final Esp32NodeService instance = Esp32NodeService._internal();
  Esp32NodeService._internal();

  static const String databaseBaseUrl =
      'https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com';

  final http.Client _client = http.Client();

  // State Notifiers
  final ValueNotifier<bool> isDeviceOnline = ValueNotifier<bool>(false);
  final ValueNotifier<NodeConnectionState> nodeConnectionState =
      ValueNotifier<NodeConnectionState>(NodeConnectionState.offline);
  final ValueNotifier<String> deviceStatusText =
      ValueNotifier<String>('Offline (Checking...)');
  final ValueNotifier<SensorData?> latestSensorData = ValueNotifier<SensorData?>(null);
  final ValueNotifier<TestStatus?> testStatusNotifier = ValueNotifier<TestStatus?>(null);
  final ValueNotifier<ChlorinationStatus?> chlorStatusNotifier = ValueNotifier<ChlorinationStatus?>(null);
  final ValueNotifier<SystemConfig> configNotifier = ValueNotifier<SystemConfig>(SystemConfig());
  final ValueNotifier<ScheduleConfig> scheduleNotifier = ValueNotifier<ScheduleConfig>(ScheduleConfig());
  final ValueNotifier<ScheduleState?> scheduleStateNotifier = ValueNotifier<ScheduleState?>(null);
  final ValueNotifier<List<WaterTestRecord>> testRecordsNotifier = ValueNotifier<List<WaterTestRecord>>([]);
  final ValueNotifier<List<TelemetryPoint>> telemetryPointsNotifier = ValueNotifier<List<TelemetryPoint>>([]);
  final ValueNotifier<bool> isAutoRefreshing = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> lastSuccessfulRefresh = ValueNotifier<DateTime?>(null);

  // Watchdog & Polling State
  Timer? _pollingTimer;
  Timer? _watchdogTimer;
  Timer? _scheduleWatcherTimer;
  int _activeListenersCount = 0;
  bool _isFetchingSensor = false;
  bool _isFetchingAux = false;
  int _auxPollCounter = 0;

  // Freshness & Offline Detection Tracking
  int? _lastObservedHeartbeat;
  DateTime? _lastHeartbeatChangeTime;
  int _consecutiveAdvancingCount = 0;

  String get lastRefreshFormatted {
    final dt = lastSuccessfulRefresh.value;
    if (dt == null) return '--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Start real-time monitoring loop
  void startMonitoring() {
    _activeListenersCount++;
    if (_activeListenersCount == 1) {
      _initWatchdogsAndPolling();
    }
  }

  /// Stop monitoring loop when screen is disposed
  void stopMonitoring() {
    _activeListenersCount = max(0, _activeListenersCount - 1);
    if (_activeListenersCount == 0) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _watchdogTimer?.cancel();
      _watchdogTimer = null;
      _scheduleWatcherTimer?.cancel();
      _scheduleWatcherTimer = null;
    }
  }

  void _initWatchdogsAndPolling() {
    // 1. Initial immediate fetch
    fetchSensorData();
    fetchAllNodeStates(forceResults: true);

    // 2. High-frequency sensor poll (every 2.0s for real-time telemetry)
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      fetchSensorData();
    });

    // 3. Status Watchdog (evaluates freshness and offline status every 1 second)
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _evaluateFreshnessWatchdog();
    });

    // 4. Auxiliary node sync (test status, pump status, schedule) every 4s
    _scheduleWatcherTimer?.cancel();
    _scheduleWatcherTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchAllNodeStates();
      _checkScheduleExecution();
    });
  }

  /// Evaluates device online/offline status cleanly with 12s hysteresis
  void _evaluateFreshnessWatchdog() {
    final now = DateTime.now();
    // Only mark offline if no advancing heartbeat seen for > 12 seconds
    if (_lastHeartbeatChangeTime != null) {
      final elapsedSec = now.difference(_lastHeartbeatChangeTime!).inSeconds;
      if (elapsedSec > 12) {
        _setOffline('Offline (Standby)');
      }
    } else if (nodeConnectionState.value == NodeConnectionState.verifying) {
      _setOffline('Offline (Standby)');
    }
  }

  void _setOffline(String reason) {
    _consecutiveAdvancingCount = 0;
    if (isDeviceOnline.value || deviceStatusText.value != reason || nodeConnectionState.value != NodeConnectionState.offline) {
      isDeviceOnline.value = false;
      deviceStatusText.value = reason;
      nodeConnectionState.value = NodeConnectionState.offline;
    }
  }

  void _setVerifying(String message) {
    if (isDeviceOnline.value || deviceStatusText.value != message || nodeConnectionState.value != NodeConnectionState.verifying) {
      isDeviceOnline.value = false;
      deviceStatusText.value = message;
      nodeConnectionState.value = NodeConnectionState.verifying;
    }
  }

  void _setOnline(String message) {
    if (!isDeviceOnline.value || deviceStatusText.value != message || nodeConnectionState.value != NodeConnectionState.online) {
      isDeviceOnline.value = true;
      deviceStatusText.value = message;
      nodeConnectionState.value = NodeConnectionState.online;
    }
  }

  /// Trigger an immediate manual/pull refresh of all telemetry and states
  Future<void> refreshAllNow() async {
    await Future.wait([
      fetchSensorData(isManual: true),
      fetchAllNodeStates(forceResults: true),
    ]);
  }

  /// Fetch SENSOR_DATA directly from Firebase REST
  Future<void> fetchSensorData({bool isManual = false}) async {
    if (_isFetchingSensor && !isManual) return;
    _isFetchingSensor = true;
    isAutoRefreshing.value = true;

    try {
      final url = Uri.parse('$databaseBaseUrl/SENSOR_DATA.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final Map<String, dynamic> json = jsonDecode(res.body);
        final data = SensorData.fromJson(json);
        latestSensorData.value = data;
        lastSuccessfulRefresh.value = DateTime.now();

        // Process telemetry point for live chart
        _addTelemetryPoint(data);

        // ---------------------------------------------------------
        // STABLE ONLINE/OFFLINE DETECTION (2 CONSECUTIVE CONFIRMATIONS)
        // ---------------------------------------------------------
        final hb = data.heartbeat;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final now = DateTime.now();

        if (hb > 1700000000000) {
          // Case A: ESP32 is using NTP Epoch Timestamp (ms)
          final ageMs = nowMs - hb;
          if (ageMs >= 0 && ageMs <= 12000) {
            if (_lastObservedHeartbeat == null || hb > _lastObservedHeartbeat!) {
              _consecutiveAdvancingCount++;
              _lastObservedHeartbeat = hb;
              _lastHeartbeatChangeTime = now;
            }

            if (_consecutiveAdvancingCount >= 2) {
              _setOnline('ESP32 Node Online');
            } else {
              _setVerifying('Verifying Link ($_consecutiveAdvancingCount/2)...');
            }
          } else {
            _setOffline('Offline (Standby)');
          }
        } else {
          // Case B: ESP32 is using millis() uptime (e.g. 132358, 140220)
          if (_lastObservedHeartbeat == null) {
            // First reading: Wait for at least 2 consecutive advancing heartbeats before showing online
            _lastObservedHeartbeat = hb;
            _lastHeartbeatChangeTime = now;
            _consecutiveAdvancingCount = 0;
            _setVerifying('Verifying Link...');
          } else if (hb != _lastObservedHeartbeat!) {
            // Heartbeat changed! Hardware is actively communicating
            _lastObservedHeartbeat = hb;
            _lastHeartbeatChangeTime = now;
            _consecutiveAdvancingCount++;

            if (_consecutiveAdvancingCount >= 2) {
              _setOnline('ESP32 Node Online');
            } else {
              _setVerifying('Verifying Link ($_consecutiveAdvancingCount/2)...');
            }
          } else {
            // Heartbeat hasn't changed this poll.
            final elapsedSec = _lastHeartbeatChangeTime != null
                ? now.difference(_lastHeartbeatChangeTime!).inSeconds
                : 999;
            if (elapsedSec > 12) {
              _setOffline('Offline (Standby)');
            }
          }
        }
      } else {
        _setOffline('Offline (No Sensor Data)');
      }
    } catch (e) {
      final elapsedSec = _lastHeartbeatChangeTime != null
          ? DateTime.now().difference(_lastHeartbeatChangeTime!).inSeconds
          : 999;
      if (elapsedSec > 12) {
        _setOffline('Offline (Network Error)');
      }
    } finally {
      _isFetchingSensor = false;
      isAutoRefreshing.value = false;
    }
  }

  void _addTelemetryPoint(SensorData data) {
    final list = List<TelemetryPoint>.from(telemetryPointsNotifier.value);
    list.add(TelemetryPoint(
      timestamp: data.receivedAt,
      tds: data.tds,
      turbidity: data.turbidityVoltage,
      temperature: data.temperature,
    ));
    if (list.length > 40) {
      list.removeRange(0, list.length - 40);
    }
    telemetryPointsNotifier.value = list;
  }

  /// Fetch TEST_STATUS, CHLORINATION_STATUS, CONFIG, SCHEDULE, TEST_RESULTS in parallel
  Future<void> fetchAllNodeStates({bool forceResults = false}) async {
    if (_isFetchingAux && !forceResults) return;
    _isFetchingAux = true;
    _auxPollCounter++;

    try {
      final futures = <Future>[
        // 1. TEST_STATUS
        _client
            .get(Uri.parse('$databaseBaseUrl/TEST_STATUS.json'))
            .timeout(const Duration(seconds: 4))
            .then((res) {
          if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
            testStatusNotifier.value = TestStatus.fromJson(jsonDecode(res.body));
          }
        }).catchError((_) {}),

        // 2. CHLORINATION_STATUS
        _client
            .get(Uri.parse('$databaseBaseUrl/CHLORINATION_STATUS.json'))
            .timeout(const Duration(seconds: 4))
            .then((res) {
          if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
            chlorStatusNotifier.value =
                ChlorinationStatus.fromJson(jsonDecode(res.body));
          }
        }).catchError((_) {}),

        // 3. CONFIG
        _client
            .get(Uri.parse('$databaseBaseUrl/CONFIG.json'))
            .timeout(const Duration(seconds: 4))
            .then((res) {
          if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
            configNotifier.value = SystemConfig.fromJson(jsonDecode(res.body));
          }
        }).catchError((_) {}),

        // 4. SCHEDULE & SCHEDULE_STATE
        _client
            .get(Uri.parse('$databaseBaseUrl/SCHEDULE.json'))
            .timeout(const Duration(seconds: 4))
            .then((res) {
          if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
            scheduleNotifier.value = ScheduleConfig.fromJson(jsonDecode(res.body));
          }
        }).catchError((_) {}),

        _client
            .get(Uri.parse('$databaseBaseUrl/SCHEDULE_STATE.json'))
            .timeout(const Duration(seconds: 4))
            .then((res) {
          if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
            scheduleStateNotifier.value =
                ScheduleState.fromJson(jsonDecode(res.body));
          }
        }).catchError((_) {}),
      ];

      // 5. TEST_RESULTS: poll every 3rd cycle (~12s) or if forced
      if (forceResults || _auxPollCounter % 3 == 0) {
        futures.add(
          _client
              .get(Uri.parse('$databaseBaseUrl/TEST_RESULTS.json'))
              .timeout(const Duration(seconds: 5))
              .then((resultsRes) {
            if (resultsRes.statusCode == 200 &&
                resultsRes.body.isNotEmpty &&
                resultsRes.body != 'null') {
              final Map<String, dynamic> map = jsonDecode(resultsRes.body);
              final List<WaterTestRecord> records = [];
              map.forEach((k, v) {
                if (v is Map) {
                  records.add(WaterTestRecord.fromJson(
                      k, Map<String, dynamic>.from(v)));
                }
              });
              records.sort((a, b) => (b.startMs ?? 0).compareTo(a.startMs ?? 0));
              testRecordsNotifier.value = records;
            }
          }).catchError((_) {}),
        );
      }

      await Future.wait(futures);
    } catch (_) {
    } finally {
      _isFetchingAux = false;
    }
  }

  // -------------------------------------------------------------
  // CONTROLLER ACTIONS (Matching index.html)
  // -------------------------------------------------------------

  /// 1. Start 60-Second Water Sampling Session
  Future<String> startWaterTest({String mode = 'Manual'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tid = 'T${now ~/ 1000}';
    final cmdId = 'TC_${now}_${Random().nextInt(1000)}';

    // 1. Update TEST_STATUS on Firebase
    await _client.put(
      Uri.parse('$databaseBaseUrl/TEST_STATUS.json'),
      body: jsonEncode({
        'state': 'RUNNING',
        'testId': tid,
        'mode': mode,
        'message': 'Sampling session active (60s)...',
        'startMs': now,
      }),
    );

    // 2. Dispatch TEST_COMMAND to ESP32
    await _client.put(
      Uri.parse('$databaseBaseUrl/TEST_COMMAND.json'),
      body: jsonEncode({
        'id': cmdId,
        'action': 'START',
        'testId': tid,
        'ts': now,
      }),
    );

    // 3. Compatibility DEVICE_COMMAND
    try {
      await _client.post(
        Uri.parse('$databaseBaseUrl/DEVICE_COMMAND.json'),
        body: jsonEncode({
          'CommandId': cmdId,
          'Command': 'START_TESTING',
          'Status': 'PENDING',
          'RequestedAt': now,
        }),
      );
    } catch (_) {}

    // Update local notifier immediately
    testStatusNotifier.value = TestStatus(
      state: 'RUNNING',
      testId: tid,
      mode: mode,
      message: 'Sampling session active (60s)...',
      startMs: now,
    );

    return tid;
  }

  /// 2. Abort / Stop Active Water Test
  Future<void> stopWaterTest() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cmdId = 'TC_${now}_${Random().nextInt(1000)}';

    await _client.patch(
      Uri.parse('$databaseBaseUrl/TEST_STATUS.json'),
      body: jsonEncode({
        'state': 'STOPPED',
        'message': 'Test stopped by operator',
        'endMs': now,
      }),
    );

    await _client.put(
      Uri.parse('$databaseBaseUrl/TEST_COMMAND.json'),
      body: jsonEncode({
        'id': cmdId,
        'action': 'STOP',
        'ts': now,
      }),
    );

    try {
      await _client.post(
        Uri.parse('$databaseBaseUrl/DEVICE_COMMAND.json'),
        body: jsonEncode({
          'CommandId': cmdId,
          'Command': 'STOP_TESTING',
          'Status': 'PENDING',
          'RequestedAt': now,
        }),
      );
    } catch (_) {}

    testStatusNotifier.value = TestStatus(
      state: 'STOPPED',
      message: 'Test stopped by operator',
      endMs: now,
    );
  }

  /// 3. Finalize 60-Second Water Sampling Session
  Future<WaterTestRecord> finalizeTestSession({
    required String tid,
    required int startMs,
    required List<SensorData> samples,
  }) async {
    double avgTemp = 25.0;
    double avgTds = 0.0;
    double avgTurb = 0.0;

    if (samples.isNotEmpty) {
      double sTemp = 0, sTds = 0, sTurb = 0;
      int tempCount = 0, tdsCount = 0, turbCount = 0;

      for (var s in samples) {
        if (s.temperature != null && s.isTempValid) {
          sTemp += s.temperature!;
          tempCount++;
        }
        if (s.tds != null) {
          sTds += s.tds!;
          tdsCount++;
        }
        if (s.turbidityVoltage != null) {
          sTurb += s.turbidityVoltage!;
          turbCount++;
        }
      }

      avgTemp = tempCount > 0 ? (sTemp / tempCount) : 25.0;
      avgTds = tdsCount > 0 ? (sTds / tdsCount) : 0.0;
      avgTurb = turbCount > 0 ? (sTurb / turbCount) : 0.0;
    } else {
      final cur = latestSensorData.value;
      avgTemp = cur?.temperature ?? 25.0;
      avgTds = cur?.tds ?? 0.0;
      avgTurb = cur?.turbidityVoltage ?? 0.0;
    }

    avgTemp = (avgTemp * 10).roundToDouble() / 10;
    avgTds = (avgTds * 10).roundToDouble() / 10;
    avgTurb = (avgTurb * 100).roundToDouble() / 100;

    final cfg = configNotifier.value;
    final bool required = (avgTds > cfg.tdsMax) || (avgTurb > cfg.turbidityMax);
    final String waterStatus = required ? 'Requires treatment' : 'Within criteria';
    final String chlorStatus = required ? 'Awaiting Coordinator' : 'Not Required';

    final now = DateTime.now().millisecondsSinceEpoch;

    final record = WaterTestRecord(
      testId: tid,
      startMs: startMs,
      endMs: now,
      tds: avgTds,
      turbidity: avgTurb,
      temperature: avgTemp,
      mode: 'Manual',
      waterStatus: waterStatus,
      chlorinationRequired: required,
      chlorinationStatus: chlorStatus,
    );

    // Save to TEST_RESULTS/$tid.json
    await _client.put(
      Uri.parse('$databaseBaseUrl/TEST_RESULTS/$tid.json'),
      body: jsonEncode({
        'testId': tid,
        'startMs': startMs,
        'endMs': now,
        'TDS': avgTds,
        'Turbidity': avgTurb,
        'Temperature': avgTemp,
        'mode': 'Manual',
        'waterStatus': waterStatus,
        'chlorinationRequired': required,
        'chlorinationStatus': chlorStatus,
      }),
    );

    // Update TEST_STATUS
    await _client.put(
      Uri.parse('$databaseBaseUrl/TEST_STATUS.json'),
      body: jsonEncode({
        'state': 'COMPLETED',
        'testId': tid,
        'mode': 'Manual',
        'message': 'Test complete: $waterStatus',
        'startMs': startMs,
        'endMs': now,
      }),
    );

    testStatusNotifier.value = TestStatus(
      state: 'COMPLETED',
      testId: tid,
      mode: 'Manual',
      message: 'Test complete: $waterStatus',
      startMs: startMs,
      endMs: now,
    );

    await fetchAllNodeStates();
    return record;
  }

  /// 4. Chemical Chlorination Dosing Pump
  Future<void> startChlorination({
    required String testId,
    required double doseMl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cmdId = 'CC_${now}_${Random().nextInt(1000)}';

    await _client.put(
      Uri.parse('$databaseBaseUrl/CHLORINATION_COMMAND.json'),
      body: jsonEncode({
        'id': cmdId,
        'action': 'START',
        'testId': testId,
        'doseMl': doseMl,
        'ts': now,
      }),
    );
  }

  /// 5. Emergency Stop Dosing Pump
  Future<void> emergencyStopChlorination() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cmdId = 'CC_${now}_${Random().nextInt(1000)}';

    await _client.put(
      Uri.parse('$databaseBaseUrl/CHLORINATION_COMMAND.json'),
      body: jsonEncode({
        'id': cmdId,
        'action': 'EMERGENCY_STOP',
        'ts': now,
      }),
    );
  }

  /// 6. Save Safety Threshold Limits
  Future<void> saveConfigThresholds({
    required double tdsMax,
    required double turbidityMax,
    required double maxDoseMl,
  }) async {
    await _client.patch(
      Uri.parse('$databaseBaseUrl/CONFIG.json'),
      body: jsonEncode({
        'tdsMax': tdsMax,
        'turbidityMax': turbidityMax,
        'maxDoseMl': maxDoseMl,
      }),
    );

    configNotifier.value = SystemConfig(
      tdsMax: tdsMax,
      turbidityMax: turbidityMax,
      maxDoseMl: maxDoseMl,
    );
  }

  /// 7. Save Daily Auto-Testing Schedule
  Future<void> saveSchedule({
    required bool enabled,
    required String time,
  }) async {
    await _client.put(
      Uri.parse('$databaseBaseUrl/SCHEDULE.json'),
      body: jsonEncode({
        'enabled': enabled,
        'time': time,
      }),
    );

    scheduleNotifier.value = ScheduleConfig(
      enabled: enabled,
      time: time,
    );
  }

  /// Check and trigger daily schedule if due
  void _checkScheduleExecution() {
    final cfg = scheduleNotifier.value;
    if (!cfg.enabled) return;

    final now = DateTime.now();
    final parts = cfg.time.split(':');
    if (parts.length < 2) return;

    final targetH = int.tryParse(parts[0]) ?? 8;
    final targetM = int.tryParse(parts[1]) ?? 0;

    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final keyStr = '${todayStr}_${cfg.time}';

    final state = scheduleStateNotifier.value;
    if (state?.lastRunDate == todayStr && state?.lastRunTime?.startsWith(cfg.time) == true) {
      return; // Already executed today
    }

    if (now.hour == targetH && now.minute == targetM) {
      // Trigger automatic sampling session
      startWaterTest(mode: 'Automatic (Scheduled)');
      _client.put(
        Uri.parse('$databaseBaseUrl/SCHEDULE_STATE.json'),
        body: jsonEncode({
          'lastRunDate': todayStr,
          'lastRunTime': '${targetH.toString().padLeft(2, '0')}:${targetM.toString().padLeft(2, '0')}:00',
          'lastRunKey': keyStr,
          'status': 'TRIGGERED_AUTOMATIC',
        }),
      );
    }
  }
}
