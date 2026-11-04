import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/esp32_node_service.dart';

class TestScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final bool showBottomNav;

  const TestScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
    this.showBottomNav = false,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with SingleTickerProviderStateMixin {
  final Esp32NodeService _espService = Esp32NodeService.instance;

  late TabController _tabController;
  int _currentTabIndex = 0;

  // 60-Second Water Sampling Controller State
  Timer? _samplingTimer;
  int _samplingStartMs = 0;
  double _samplingProgressPct = 0.0;
  int _samplingSecondsRemaining = 60;
  final List<SensorData> _activeSamplingSamples = [];
  WaterTestRecord? _latestCompletedRecord;

  // Chlorination Dosing State
  final TextEditingController _doseTestIdCtrl = TextEditingController();
  final TextEditingController _doseMlCtrl = TextEditingController(text: '10');

  // Threshold Configuration State
  final TextEditingController _tdsMaxCtrl = TextEditingController(text: '500');
  final TextEditingController _turbMaxCtrl = TextEditingController(text: '5.0');
  final TextEditingController _maxDoseCtrl = TextEditingController(text: '50');

  // Daily Schedule State
  bool _scheduleEnabled = false;
  String _scheduleTime = '08:00';
  Timer? _countdownTimer;

  // Rotating motor animation for dosing pump
  late AnimationController _motorAnimCtrl;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });

    _motorAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Start IoT Node live monitoring
    _espService.startMonitoring();

    // Listen to Firebase status changes
    _espService.testStatusNotifier.addListener(_onTestStatusChanged);
    _espService.chlorStatusNotifier.addListener(_onChlorStatusChanged);
    _espService.configNotifier.addListener(_onConfigChanged);
    _espService.scheduleNotifier.addListener(_onScheduleChanged);

    // Initial config sync
    _syncConfigInputs();

    // Schedule countdown updater
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    _countdownTimer?.cancel();
    _motorAnimCtrl.dispose();
    _tabController.dispose();
    _doseTestIdCtrl.dispose();
    _doseMlCtrl.dispose();
    _tdsMaxCtrl.dispose();
    _turbMaxCtrl.dispose();
    _maxDoseCtrl.dispose();

    _espService.testStatusNotifier.removeListener(_onTestStatusChanged);
    _espService.chlorStatusNotifier.removeListener(_onChlorStatusChanged);
    _espService.configNotifier.removeListener(_onConfigChanged);
    _espService.scheduleNotifier.removeListener(_onScheduleChanged);

    _espService.stopMonitoring();
    super.dispose();
  }

  void _syncConfigInputs() {
    final cfg = _espService.configNotifier.value;
    _tdsMaxCtrl.text = cfg.tdsMax.toStringAsFixed(0);
    _turbMaxCtrl.text = cfg.turbidityMax.toStringAsFixed(1);
    _maxDoseCtrl.text = cfg.maxDoseMl.toStringAsFixed(0);

    final sched = _espService.scheduleNotifier.value;
    _scheduleEnabled = sched.enabled;
    _scheduleTime = sched.time;
  }

  void _onConfigChanged() {
    if (mounted) _syncConfigInputs();
  }

  void _onScheduleChanged() {
    if (mounted) {
      final sched = _espService.scheduleNotifier.value;
      setState(() {
        _scheduleEnabled = sched.enabled;
        _scheduleTime = sched.time;
      });
    }
  }

  void _onChlorStatusChanged() {
    final chlor = _espService.chlorStatusNotifier.value;
    if (chlor?.state == 'SIMULATION_RUNNING') {
      if (!_motorAnimCtrl.isAnimating) _motorAnimCtrl.repeat();
    } else {
      if (_motorAnimCtrl.isAnimating) _motorAnimCtrl.stop();
    }
    if (mounted) setState(() {});
  }

  void _onTestStatusChanged() {
    final ts = _espService.testStatusNotifier.value;
    if (ts == null) return;

    if (ts.state == 'RUNNING' && _samplingTimer == null) {
      // Sync with active sampling
      final start = ts.startMs ?? DateTime.now().millisecondsSinceEpoch;
      _startSamplingTracker(start, ts.testId ?? 'T_ACTIVE');
    } else if (ts.state == 'STOPPED' || ts.state == 'COMPLETED') {
      _stopSamplingTracker();
    }
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------------
  // SAMPLING CONTROLLER (60 SECONDS)
  // -------------------------------------------------------------
  void _triggerStartWaterTest() async {
    final tid = await _espService.startWaterTest(mode: 'Manual (60s)');
    final now = DateTime.now().millisecondsSinceEpoch;
    _startSamplingTracker(now, tid);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Water test $tid started! Sampling for 60s...'),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _triggerStopWaterTest() async {
    _stopSamplingTracker();
    await _espService.stopWaterTest();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Water test stopped by operator.'),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }

  void _startSamplingTracker(int startMs, String tid) {
    _samplingTimer?.cancel();
    _samplingStartMs = startMs;
    _activeSamplingSamples.clear();

    const durationMs = 60000;

    _samplingTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - _samplingStartMs;
      final pct = (elapsed / durationMs).clamp(0.0, 1.0);
      final remSec = max(0, ((durationMs - elapsed) / 1000).ceil());

      // Collect sample every ~1s
      final curSensor = _espService.latestSensorData.value;
      if (curSensor != null && timer.tick % 4 == 0) {
        _activeSamplingSamples.add(curSensor);
      }

      if (mounted) {
        setState(() {
          _samplingProgressPct = pct;
          _samplingSecondsRemaining = remSec;
        });
      }

      if (pct >= 1.0) {
        timer.cancel();
        _samplingTimer = null;
        await _onSamplingCompleted(tid, startMs);
      }
    });
  }

  void _stopSamplingTracker() {
    _samplingTimer?.cancel();
    _samplingTimer = null;
    if (mounted) {
      setState(() {
        _samplingProgressPct = 0.0;
        _samplingSecondsRemaining = 60;
      });
    }
  }

  Future<void> _onSamplingCompleted(String tid, int startMs) async {
    final record = await _espService.finalizeTestSession(
      tid: tid,
      startMs: startMs,
      samples: _activeSamplingSamples,
    );

    if (mounted) {
      setState(() {
        _latestCompletedRecord = record;
        _samplingProgressPct = 1.0;
        _samplingSecondsRemaining = 0;
      });

      if (record.chlorinationRequired) {
        _doseTestIdCtrl.text = record.testId;
      }

      final isReq = record.chlorinationRequired;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test ${record.testId} Completed: ${record.waterStatus} (TDS: ${record.tds.toStringAsFixed(1)} ppm)',
          ),
          backgroundColor: isReq ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
          action: isReq
              ? SnackBarAction(
                  label: 'Dose Now',
                  textColor: Colors.white,
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                )
              : null,
        ),
      );
    }
  }

  // -------------------------------------------------------------
  // BUILD METHOD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSystemStatusBar(),
            _buildTabBar(),
            Expanded(
              child: _buildCurrentTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildTabLiveAndTest();
      case 1:
        return _buildTabChlorination();
      case 2:
        return _buildTabConfigAndSchedule();
      case 3:
        return _buildTabHistory();
      default:
        return _buildTabLiveAndTest();
    }
  }

  // -------------------------------------------------------------
  // APP BAR & SYSTEM STATUS BAR
  // -------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF003652),
      elevation: 2,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sensors_rounded, color: Color(0xFF00B4D8), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'JalSanket IoT Node',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Hardware Telemetry & Dosing Control',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sync Hardware Data',
          icon: _isManualRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          onPressed: _isManualRefreshing
              ? null
              : () async {
                  setState(() => _isManualRefreshing = true);
                  await _espService.refreshAllNow();
                  if (!mounted) return;
                  setState(() => _isManualRefreshing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hardware telemetry & states synced'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
        ),
      ],
    );
  }

  Widget _buildSystemStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Cloud & Auto-sync timestamp
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Cloud',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 11, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: _espService.isAutoRefreshing,
                builder: (ctx, isSyncing, _) {
                  return ValueListenableBuilder<DateTime?>(
                    valueListenable: _espService.lastSuccessfulRefresh,
                    builder: (ctx, _, _) {
                      final timeStr = _espService.lastRefreshFormatted;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSyncing ? Icons.sync : Icons.schedule_rounded,
                            size: 13,
                            color: isSyncing ? const Color(0xFF00B4D8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isSyncing ? 'Syncing...' : 'Sync $timeStr',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isSyncing ? const Color(0xFF0077B6) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Right: ESP32 status + Firmware
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<NodeConnectionState>(
                valueListenable: _espService.nodeConnectionState,
                builder: (ctx, nodeState, _) {
                  Color badgeBg;
                  Color badgeBorder;
                  Color dotColor;
                  Color textColor;
                  String label;

                  switch (nodeState) {
                    case NodeConnectionState.online:
                      badgeBg = const Color(0xFFECFDF5);
                      badgeBorder = const Color(0xFFA7F3D0);
                      dotColor = const Color(0xFF10B981);
                      textColor = const Color(0xFF065F46);
                      label = 'ESP32 Online';
                      break;
                    case NodeConnectionState.verifying:
                      badgeBg = const Color(0xFFFEF3C7);
                      badgeBorder = const Color(0xFFFDE68A);
                      dotColor = const Color(0xFFF59E0B);
                      textColor = const Color(0xFFB45309);
                      label = _espService.deviceStatusText.value;
                      break;
                    case NodeConnectionState.offline:
                      badgeBg = const Color(0xFFFEF2F2);
                      badgeBorder = const Color(0xFFFECACA);
                      dotColor = const Color(0xFFEF4444);
                      textColor = const Color(0xFF991B1B);
                      label = 'ESP32 Offline';
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              // Firmware Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'v2.4',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (idx) {
          setState(() => _currentTabIndex = idx);
        },
        labelColor: const Color(0xFF004D73),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF00B4D8),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.sensors_rounded, size: 18), text: 'Live & Test'),
          Tab(icon: Icon(Icons.water_rounded, size: 18), text: 'Dosing'),
          Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Config'),
          Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: LIVE SENSORS & 60S WATER TEST
  // -------------------------------------------------------------
  Widget _buildTabLiveAndTest() {
    return RefreshIndicator(
      color: const Color(0xFF00B4D8),
      backgroundColor: Colors.white,
      onRefresh: () async {
        await _espService.refreshAllNow();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3 Live Sensor Cards
            ValueListenableBuilder<bool>(
              valueListenable: _espService.isDeviceOnline,
              builder: (ctx, isOnline, _) {
                return ValueListenableBuilder<SensorData?>(
                  valueListenable: _espService.latestSensorData,
                  builder: (ctx, sensor, _) {
                    return Column(
                      children: [
                        _buildTemperatureCard(sensor, isOnline),
                        const SizedBox(height: 12),
                        _buildTdsCard(sensor, isOnline),
                        const SizedBox(height: 12),
                        _buildTurbidityCard(sensor, isOnline),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),

            // Water Sampling Controller Card
            _buildTestingControllerCard(),
            const SizedBox(height: 16),

            // Latest Completed Result Banner (if any)
            if (_latestCompletedRecord != null)
              _buildCompletedResultCard(_latestCompletedRecord!),
          ],
        ),
      ),
    );
  }

  // Sensor Card 1: Water Temperature (Pin 4 - DS18B20)
  Widget _buildTemperatureCard(SensorData? data, bool isOnline) {
    final isLive = isOnline && (data?.isTempLive ?? false);
    final tempVal = data?.temperature;
    final tempStr = (tempVal != null && data!.isTempValid)
        ? tempVal.toStringAsFixed(2)
        : (data?.temperatureLastKnown?.toStringAsFixed(2) ?? '--');

    return _buildSensorCard(
      title: 'WATER TEMPERATURE',
      pin: 'PIN 4 (DS18B20)',
      icon: Icons.thermostat_rounded,
      iconColor: const Color(0xFF0284C7),
      value: tempStr,
      unit: '°C',
      isLive: isLive,
      statusLabel: isLive ? 'LIVE' : (isOnline ? 'STANDBY' : 'OFFLINE'),
      diagnosticText: isLive
          ? 'Pin 4: DS18B20 digital temperature probe connected & streaming'
          : (isOnline ? 'Pin 4: Standby' : 'ESP32 Offline • Showing last recorded temperature reading'),
    );
  }

  // Sensor Card 2: Total Dissolved Solids (Pin 34)
  Widget _buildTdsCard(SensorData? data, bool isOnline) {
    final isLive = isOnline && (data?.isTdsLive ?? false);
    final tdsVal = data?.tds;
    final tdsStr = (tdsVal != null)
        ? tdsVal.toStringAsFixed(1)
        : (data?.tdsLastKnown?.toStringAsFixed(1) ?? '--');

    final cfg = _espService.configNotifier.value;
    final isSafe = (tdsVal ?? 0) <= cfg.tdsMax;
    final voltStr = data?.tdsVoltage != null ? ' (${data!.tdsVoltage!.toStringAsFixed(3)} V)' : '';

    return _buildSensorCard(
      title: 'TOTAL DISSOLVED SOLIDS (TDS)',
      pin: 'PIN 34 (ANALOG)',
      icon: Icons.opacity_rounded,
      iconColor: const Color(0xFF0D9488),
      value: tdsStr,
      unit: 'ppm',
      isLive: isLive,
      statusLabel: isLive ? 'LIVE' : (isOnline ? 'STANDBY' : 'OFFLINE'),
      extraPill: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isSafe ? '≤ ${cfg.tdsMax.toInt()} ppm (BIS Safe)' : 'Exceeds Standard',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isSafe ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
        ),
      ),
      diagnosticText: isLive
          ? 'Pin 34: Sensor connected$voltStr • Clean freshwater range'
          : (isOnline ? 'Pin 34: Standby' : 'ESP32 Offline • Showing last known TDS value'),
    );
  }

  // Sensor Card 3: Turbidity Sensor (Pin 35)
  Widget _buildTurbidityCard(SensorData? data, bool isOnline) {
    final isLive = isOnline && (data?.isTurbidityLive ?? false);
    final turbVolt = data?.turbidityVoltage;
    final turbStr = (turbVolt != null)
        ? turbVolt.toStringAsFixed(3)
        : (data?.turbidityLastKnown?.toStringAsFixed(3) ?? '--');

    final ntuVal = data?.turbidityNTU;
    final ntuStr = (ntuVal != null) ? '(${ntuVal.toStringAsFixed(1)} NTU)' : '';

    final cfg = _espService.configNotifier.value;
    final isClear = (turbVolt ?? 0) <= cfg.turbidityMax;

    return _buildSensorCard(
      title: 'TURBIDITY SENSOR',
      pin: 'PIN 35 (PHOTOELECTRIC)',
      icon: Icons.waves_rounded,
      iconColor: const Color(0xFF7C3AED),
      value: turbStr,
      unit: 'V $ntuStr',
      isLive: isLive,
      statusLabel: isLive ? 'LIVE' : (isOnline ? 'STANDBY' : 'OFFLINE'),
      extraPill: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isClear ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isClear ? 'Clear Water' : 'Cloudy / Suspended',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isClear ? const Color(0xFF15803D) : const Color(0xFFB45309),
          ),
        ),
      ),
      diagnosticText: isLive
          ? 'Pin 35: Photoelectric turbidity sensor streaming live'
          : (isOnline ? 'Pin 35: Standby' : 'ESP32 Offline • Showing last recorded optical voltage'),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String pin,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required bool isLive,
    required String statusLabel,
    Widget? extraPill,
    required String diagnosticText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003652).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      pin,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (extraPill != null) ...[
                extraPill,
                const SizedBox(width: 6),
              ],
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isLive ? const Color(0xFF059669) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value & Unit Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: Color(0xFF003652),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Diagnostic Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 13,
                  color: isLive ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    diagnosticText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isLive ? const Color(0xFF15803D) : const Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Testing Session Controller Card (Matching index.html)
  Widget _buildTestingControllerCard() {
    return ValueListenableBuilder<TestStatus?>(
      valueListenable: _espService.testStatusNotifier,
      builder: (ctx, testStatus, _) {
        final state = testStatus?.state ?? 'IDLE';
        final isRunning = state == 'RUNNING';
        final testId = testStatus?.testId ?? 'None';
        final mode = testStatus?.mode ?? 'Manual (60s)';
        final message = testStatus?.message ?? 'Idle and ready for sampling';

        Color badgeBg;
        Color badgeFg;
        if (isRunning) {
          badgeBg = const Color(0xFFFEF3C7);
          badgeFg = const Color(0xFFB45309);
        } else if (state == 'COMPLETED') {
          badgeBg = const Color(0xFFECFDF5);
          badgeFg = const Color(0xFF059669);
        } else if (state == 'STOPPED') {
          badgeBg = const Color(0xFFFEF2F2);
          badgeFg = const Color(0xFFDC2626);
        } else {
          badgeBg = const Color(0xFFF1F5F9);
          badgeFg = const Color(0xFF475569);
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003652).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D73).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: Color(0xFF004D73), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Water Quality Test Controller',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Automated 60s Sensor Averaging & Analysis',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isRunning ? 'RUNNING (SAMPLING)' : state,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeFg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Details Row
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _testMetaCol('Test ID', testId, isMono: true),
                    _testMetaCol('Mode', mode),
                    _testMetaCol('Status', isRunning ? 'Sampling...' : state),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRunning
                        ? 'Sampling: $_samplingSecondsRemaining s remaining'
                        : (state == 'COMPLETED' ? 'Sampling finished (100%)' : 'Awaiting start trigger'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  Text(
                    '${(_samplingProgressPct * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF004D73)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _samplingProgressPct,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isRunning ? const Color(0xFF00B4D8) : const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isRunning ? null : _triggerStartWaterTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D73),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text(
                        'Start Water Test',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: isRunning ? _triggerStopWaterTest : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text(
                        'Stop',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _testMetaCol(String label, String value, {bool isMono = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontFamily: isMono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedResultCard(WaterTestRecord record) {
    final isReq = record.chlorinationRequired;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReq ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReq ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isReq ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: isReq ? const Color(0xFFDC2626) : const Color(0xFF059669),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReq ? 'TREATMENT REQUIRED' : 'WATER WITHIN CRITERIA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isReq ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Session: ${record.testId}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isReq ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricPill('Avg TDS', '${record.tds.toStringAsFixed(1)} ppm'),
              _metricPill('Avg Turbidity', '${record.turbidity.toStringAsFixed(2)} V'),
              _metricPill('Avg Temp', '${record.temperature.toStringAsFixed(1)} °C'),
            ],
          ),
          if (isReq) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                _doseTestIdCtrl.text = record.testId;
                _tabController.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.water_drop_rounded, size: 18),
              label: const Text(
                'Open Chlorination Dosing for this Test',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'monospace'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: CHLORINATION & DOSING PUMP
  // -------------------------------------------------------------
  Widget _buildTabChlorination() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dosing Pump Status & Motor Graphic
          ValueListenableBuilder<ChlorinationStatus?>(
            valueListenable: _espService.chlorStatusNotifier,
            builder: (ctx, chlor, _) {
              final state = chlor?.state ?? 'STANDBY';
              final isRunning = state == 'SIMULATION_RUNNING';

              Color badgeBg = const Color(0xFFF1F5F9);
              Color badgeFg = const Color(0xFF475569);
              if (isRunning) {
                badgeBg = const Color(0xFFFEF3C7);
                badgeFg = const Color(0xFFB45309);
              } else if (state == 'SIMULATION_COMPLETED') {
                badgeBg = const Color(0xFFECFDF5);
                badgeFg = const Color(0xFF059669);
              } else if (state == 'ERROR') {
                badgeBg = const Color(0xFFFEF2F2);
                badgeFg = const Color(0xFFDC2626);
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003652).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dosing Pump Hardware',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeFg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rotating Motor Graphic
                    RotationTransition(
                      turns: _motorAnimCtrl,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isRunning ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRunning ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.rotate_right_rounded,
                          size: 44,
                          color: isRunning ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      isRunning ? 'Relay / Motor Active (GPIO 25)' : 'Motor Idle (GPIO 25)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chlor?.message ?? 'Pump is stationary. Standing by for dosing authorization.',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Dosing Controls Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dispense Chlorine Solution',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Authorize chemical pump to inject chlorine into storage tank',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Target Test ID Field
                TextField(
                  controller: _doseTestIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Target Test ID',
                    hintText: 'e.g. T1793745519',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Dose Volume Field
                TextField(
                  controller: _doseMlCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chlorine Dosage (ml)',
                    hintText: 'e.g. 10',
                    suffixText: 'ml',
                    prefixIcon: const Icon(Icons.water_drop_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Dosage Chips
                Wrap(
                  spacing: 8,
                  children: [5.0, 10.0, 15.0, 25.0].map((v) {
                    return ActionChip(
                      label: Text('${v.toInt()} ml'),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onPressed: () {
                        setState(() => _doseMlCtrl.text = v.toInt().toString());
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Dosage Guideline
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    'Standard ratio: 2.5 ml chlorine solution per 1,000 Liters of tank volume.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    final tid = _doseTestIdCtrl.text.trim();
                    final dose = double.tryParse(_doseMlCtrl.text.trim());
                    if (tid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid Test ID.')),
                      );
                      return;
                    }
                    if (dose == null || dose <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid dosage (ml).')),
                      );
                      return;
                    }

                    await _espService.startChlorination(testId: tid, doseMl: dose);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chlorination request dispatched ($dose ml for $tid)'),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D73),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.colorize_rounded, size: 20),
                  label: const Text(
                    'Start Chlorination Dosing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                // Emergency Stop Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await _espService.emergencyStopChlorination();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🚨 EMERGENCY STOP DISPATCHED to Dosing Relay!'),
                        backgroundColor: Color(0xFFDC2626),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.dangerous_rounded, size: 20),
                  label: const Text(
                    'EMERGENCY STOP PUMP',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: THRESHOLDS & DAILY SCHEDULE
  // -------------------------------------------------------------
  Widget _buildTabConfigAndSchedule() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Threshold Limits Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Safety Thresholds & Limits',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Define maximum safe contamination boundaries for automated flags',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),

                // Preset Chips
                Row(
                  children: [
                    _presetChip('Potable (300)', 300, 1.0, 25),
                    const SizedBox(width: 8),
                    _presetChip('WHO (500)', 500, 5.0, 50),
                    const SizedBox(width: 8),
                    _presetChip('Relaxed (800)', 800, 8.0, 50),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _tdsMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'TDS Max Limit (ppm)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _turbMaxCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Turbidity Max Limit (V)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _maxDoseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Single Dose (ml)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: () async {
                    final tds = double.tryParse(_tdsMaxCtrl.text) ?? 500;
                    final turb = double.tryParse(_turbMaxCtrl.text) ?? 5.0;
                    final dose = double.tryParse(_maxDoseCtrl.text) ?? 50;

                    await _espService.saveConfigThresholds(
                      tdsMax: tds,
                      turbidityMax: turb,
                      maxDoseMl: dose,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Threshold limits saved successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D73),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Thresholds'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily Automated Test Schedule Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Automated Schedule',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Switch(
                      value: _scheduleEnabled,
                      activeThumbColor: const Color(0xFF004D73),
                      activeTrackColor: const Color(0xFFBAE6FD),
                      onChanged: (val) {
                        setState(() => _scheduleEnabled = val);
                        _espService.saveSchedule(enabled: val, time: _scheduleTime);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Node automatically initiates water sampling session every day',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Scheduled Time display
                InkWell(
                  onTap: () async {
                    final parts = _scheduleTime.split(':');
                    final initTime = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 8,
                      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                    );
                    final picked = await showTimePicker(context: context, initialTime: initTime);
                    if (picked != null) {
                      final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      setState(() => _scheduleTime = str);
                      await _espService.saveSchedule(enabled: _scheduleEnabled, time: str);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: Color(0xFF004D73), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Scheduled Time: $_scheduleTime',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Countdown to Next Trigger
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _scheduleEnabled ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _scheduleEnabled ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _scheduleEnabled ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                        size: 16,
                        color: _scheduleEnabled ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scheduleEnabled
                              ? 'Schedule ACTIVE: Daily test set for $_scheduleTime'
                              : 'Schedule is OFF: Daily automated testing disabled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _scheduleEnabled ? const Color(0xFF065F46) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: () {
                    _espService.startWaterTest(mode: 'Automatic (Triggered Now)');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheduled test triggered immediately!'),
                        backgroundColor: Color(0xFF0284C7),
                      ),
                    );
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF004D73),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: const Text('Trigger Scheduled Test Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, double tds, double turb, double dose) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _tdsMaxCtrl.text = tds.toInt().toString();
          _turbMaxCtrl.text = turb.toStringAsFixed(1);
          _maxDoseCtrl.text = dose.toInt().toString();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: TEST RESULTS HISTORY & CSV EXPORT
  // -------------------------------------------------------------
  Widget _buildTabHistory() {
    return ValueListenableBuilder<List<WaterTestRecord>>(
      valueListenable: _espService.testRecordsNotifier,
      builder: (ctx, records, _) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No test records found.', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _espService.fetchAllNodeStates(),
                  child: const Text('Refresh from Database'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF00B4D8),
          backgroundColor: Colors.white,
          onRefresh: () async {
            await _espService.fetchAllNodeStates(forceResults: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary & Export Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recorded Tests (${records.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportToCsv(records),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D73),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Records List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final r = records[idx];
                  final isSafe = !r.chlorinationRequired;
                  final timeStr = r.endMs != null
                      ? DateTime.fromMillisecondsSinceEpoch(r.endMs!).toLocal().toString().substring(0, 16)
                      : '--';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.testId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D73),
                                fontFamily: 'monospace',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSafe ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.waterStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSafe ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$timeStr • Mode: ${r.mode}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniMetric('TDS', '${r.tds.toStringAsFixed(1)} ppm'),
                            _miniMetric('Turbidity', '${r.turbidity.toStringAsFixed(2)} V'),
                            _miniMetric('Temp', '${r.temperature.toStringAsFixed(1)} °C'),
                            _miniMetric('Chlorine', r.chlorinationStatus),
                          ],
                        ),
                        if (r.chlorinationRequired && r.chlorinationStatus != 'Dosing Completed') ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                _doseTestIdCtrl.text = r.testId;
                                _tabController.animateTo(1);
                              },
                              icon: const Icon(Icons.water_drop_rounded, size: 14),
                              label: const Text('Dose this test', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _miniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  void _exportToCsv(List<WaterTestRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('TestId,Timestamp,Mode,TDS_ppm,Turbidity_V,Temp_C,WaterStatus,ChlorinationRequired,ChlorinationStatus');
    for (final r in records) {
      final ts = r.endMs ?? r.startMs ?? 0;
      final dt = ts > 0 ? DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String() : '';
      buffer.writeln('${r.testId},$dt,${r.mode},${r.tds},${r.turbidity},${r.temperature},${r.waterStatus},${r.chlorinationRequired},${r.chlorinationStatus}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV records copied to clipboard (${records.length} tests).'),
        backgroundColor: const Color(0xFF004D73),
      ),
    );
  }
}
