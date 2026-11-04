import 'package:flutter/material.dart';

class SensorNodeScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const SensorNodeScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  State<SensorNodeScreen> createState() => _SensorNodeScreenState();
}

class _SensorNodeScreenState extends State<SensorNodeScreen> {
  // Telemetry values
  int _tds = 480;
  double _turbidity = 3.8;
  double _ph = 7.1;
  double _temp = 28.4;
  int _battery = 73;
  int _bleRssi = -62;
  String _lastPing = '4 min ago';
  bool _isRefreshing = false;

  void _refreshTelemetry() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _tds = 482;
      _turbidity = 3.7;
      _ph = 7.2;
      _temp = 28.5;
      _battery = 74;
      _bleRssi = -60;
      _lastPing = 'Just now';
      _isRefreshing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('BLE Telemetry updated from ESP32 Node-01'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  void _showSensorDetails({
    required String title,
    required String value,
    required String unit,
    required String standard,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      Text(
                        'Current Reading: $value $unit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 14),
            _buildDetailRow('BIS IS 10500 Standard Limit', standard),
            const SizedBox(height: 10),
            _buildDetailRow('Clinical & Outbreak Impact', description),
            const SizedBox(height: 10),
            _buildDetailRow('Sensor Hardware', 'Submersible analog probe with optoelectronic photodiode (ESP32 ADC1).'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _refreshTelemetry();
                },
                icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Trigger Instant BLE Ping',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1E36),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Radiant Header
            _buildTopHeaderCard(),

            const SizedBox(height: 12),

            // Scrollable Telemetry View
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // 2. Connected Node Banner Card
                    _buildConnectedNodeCard(),

                    const SizedBox(height: 14),

                    // 3. 2x2 Grid of Telemetry Cards
                    _buildTelemetryGrid(),

                    const SizedBox(height: 14),

                    // 4. Node Battery Level Card
                    _buildBatteryCard(),

                    const SizedBox(height: 14),

                    // 5. How The Node Works Card
                    _buildHowNodeWorksCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top Header Banner
  Widget _buildTopHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF0369A1),
            Color(0xFF075985),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Sensor Node',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ESP32 IOT SENSOR TELEMETRY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBAE6FD),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Droplet art
          Image.asset(
            'assets/images/water_drop_ripple.png',
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.water_drop,
              color: Color(0xFF38BDF8),
              size: 28,
            ),
          ),

          const SizedBox(width: 8),

          // ONLINE BLE badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
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
                const SizedBox(width: 5),
                const Text(
                  'ONLINE BLE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6EE7B7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Connected Node Header Card
  Widget _buildConnectedNodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF032242),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0E4A7D)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF032242).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left water icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0C3D6A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF38BDF8),
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          // Node Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Pimpri Well 1 (Node-01)',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.bluetooth_rounded,
                      color: Color(0xFF38BDF8),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'BLE Signal: $_bleRssi dBm',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF38BDF8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last ping: $_lastPing',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Antenna/Radio Broadcast Waves Icon
          InkWell(
            onTap: _refreshTelemetry,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0C3D6A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
              ),
              child: _isRefreshing
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF38BDF8),
                      ),
                    )
                  : const Icon(
                      Icons.sensors_rounded,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. 2x2 Grid of Telemetry Cards
  Widget _buildTelemetryGrid() {
    return Column(
      children: [
        // Row 1: TDS & Turbidity
        Row(
          children: [
            // TDS Card
            Expanded(
              child: _buildTelemetryCard(
                title: 'TDS (Total Dissolved Solids)',
                value: '$_tds',
                unit: 'ppm',
                statusText: 'Acceptable',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFF3B2E15),
                waveColor: const Color(0xFFF59E0B),
                onTap: () {
                  _showSensorDetails(
                    title: 'Total Dissolved Solids (TDS)',
                    value: '$_tds',
                    unit: 'ppm',
                    standard: 'Desirable: < 500 ppm | Permissible: 2,000 ppm',
                    description: 'TDS measures dissolved minerals and salts. High spikes indicate runoff contamination from agricultural fields or sewage seepage.',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.water_drop,
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Turbidity Card
            Expanded(
              child: _buildTelemetryCard(
                title: 'Turbidity (Optical NTU)',
                value: '$_turbidity',
                unit: 'NTU',
                statusText: 'Clear',
                icon: Icons.visibility_outlined,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFF064E3B),
                waveColor: const Color(0xFF10B981),
                onTap: () {
                  _showSensorDetails(
                    title: 'Turbidity (Optical Turbidity)',
                    value: '$_turbidity',
                    unit: 'NTU',
                    standard: 'Desirable: < 1.0 NTU | Permissible: 5.0 NTU',
                    description: 'Cloudiness caused by suspended particles. Particles shield pathogens from chlorine disinfection. 3.8 NTU is elevated but manageable with chlorination.',
                    color: const Color(0xFF10B981),
                    icon: Icons.visibility_rounded,
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: pH Level & Water Temperature
        Row(
          children: [
            // pH Level Card
            Expanded(
              child: _buildTelemetryCard(
                title: 'pH Level',
                value: '$_ph',
                unit: '',
                statusText: 'Optimal',
                icon: Icons.science_outlined,
                iconColor: const Color(0xFFC084FC),
                iconBgColor: const Color(0xFF3B1D48),
                waveColor: const Color(0xFFA855F7),
                onTap: () {
                  _showSensorDetails(
                    title: 'pH Level Sensor',
                    value: '$_ph',
                    unit: 'pH',
                    standard: 'Permissible Limit: 6.5 – 8.5',
                    description: 'Chlorine disinfection works most effectively at pH 6.5 to 7.5. At 7.1, hypochlorous acid (HOCl) formation is at peak antimicrobial potency.',
                    color: const Color(0xFFA855F7),
                    icon: Icons.science_rounded,
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Water Temperature Card
            Expanded(
              child: _buildTelemetryCard(
                title: 'Water Temperature',
                value: '$_temp',
                unit: '°C',
                statusText: 'Normal',
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFF38BDF8),
                iconBgColor: const Color(0xFF0C4A6E),
                waveColor: const Color(0xFF0284C7),
                onTap: () {
                  _showSensorDetails(
                    title: 'Water Temperature Probe',
                    value: '$_temp',
                    unit: '°C',
                    standard: 'Ambient Baseline: 24°C – 30°C',
                    description: 'Warm surface water promotes rapid bacterial reproduction of E. coli and Vibrio cholerae. High temperature shortens chlorine residual half-life.',
                    color: const Color(0xFF0284C7),
                    icon: Icons.thermostat_rounded,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String unit,
    required String statusText,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color waveColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 155,
        decoration: BoxDecoration(
          color: const Color(0xFF0C1F37),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E3A5F)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C1F37).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Bottom Glowing Neon Wave Contour
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 50,
                child: CustomPaint(
                  painter: NeonWavePainter(color: waveColor),
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon square
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: iconColor.withValues(alpha: 0.6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Value & Unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF34D399),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Node Battery Level Card
  Widget _buildBatteryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F37),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A5F)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1F37).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle wave at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 35,
              child: CustomPaint(
                painter: NeonWavePainter(color: const Color(0xFF0284C7)),
              ),
            ),

            Row(
              children: [
                // Battery green icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.battery_5_bar_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // Battery label and percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Node Battery Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_battery%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_rounded,
                            color: Color(0xFF34D399),
                            size: 12,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Good',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Battery Progress Bar
                SizedBox(
                  width: 130,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 10,
                            color: const Color(0xFF1E293B),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 130 * (_battery / 100.0),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_battery%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. How The Node Works Card
  Widget _buildHowNodeWorksCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF032242),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF0E4A7D)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF032242).withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Droplet Ripple art on bottom right
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  'assets/images/water_drop_ripple.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

            // Text Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'HOW THE NODE WORKS',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: const Text(
                      'ESP32 microcontroller reads TDS and turbidity sensors every 15 minutes. Readings are sent over BLE to the phone. A red strip test + high TDS + high turbidity together trigger a combined high-confidence alert. (Simulated — real hardware on the roadmap)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBAE6FD),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Neon Glowing Wave Contour Lines
class NeonWavePainter extends CustomPainter {
  final Color color;

  NeonWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final path = Path();
    path.moveTo(0, height * 0.75);
    path.cubicTo(
      width * 0.35, height * 0.35,
      width * 0.65, height * 0.95,
      width, height * 0.55,
    );

    // Glow stroke
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glowPaint);

    // Crisp neon stroke
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant NeonWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
