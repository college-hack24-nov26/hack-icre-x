import 'package:flutter/material.dart';

class SourcePassportSheet extends StatefulWidget {
  final String sourceName;
  final String village;
  final String nodeId;
  final int totalScore;
  final String status; // 'Safe', 'At Risk', 'Contaminated'
  final int confidencePercent;
  final int cleaningGapDays;

  const SourcePassportSheet({
    super.key,
    this.sourceName = 'Pimpri Well 1',
    this.village = 'Pimpri',
    this.nodeId = '01',
    this.totalScore = 25,
    this.status = 'Safe',
    this.confidencePercent = 25,
    this.cleaningGapDays = 45,
  });

  static void show(
    BuildContext context, {
    String sourceName = 'Pimpri Well 1',
    String village = 'Pimpri',
    String nodeId = '01',
    int totalScore = 25,
    String status = 'Safe',
    int confidencePercent = 25,
    int cleaningGapDays = 45,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SourcePassportSheet(
        sourceName: sourceName,
        village: village,
        nodeId: nodeId,
        totalScore: totalScore,
        status: status,
        confidencePercent: confidencePercent,
        cleaningGapDays: cleaningGapDays,
      ),
    );
  }

  @override
  State<SourcePassportSheet> createState() => _SourcePassportSheetState();
}

class _SourcePassportSheetState extends State<SourcePassportSheet> {
  late int _cleaningGapDays;
  late int _totalScore;

  @override
  void initState() {
    super.initState();
    _cleaningGapDays = widget.cleaningGapDays;
    _totalScore = widget.totalScore;
  }

  void _markCleanedToday() {
    setState(() {
      _cleaningGapDays = 0;
      _totalScore = (_totalScore - 10).clamp(0, 100);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked cleaned today! Cleaning gap reset to 0d.'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  void _openVillagerView() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F253E),
        title: Row(
          children: const [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Villager Potability Pass',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sourceName} (${widget.village})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ Water source is routinely chlorinated and monitored.\n'
              '💧 Boil water before drinking during monsoon season.\n'
              '🛡 Validated by Gram Panchayat & ASHA Health Team.',
              style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF08182B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top drag handle & close button row
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Source Header Row
            Row(
              children: [
                // Green indicator dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // Source icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C3D6A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.sourceName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C4A6E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0284C7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, size: 5, color: Color(0xFF38BDF8)),
                                SizedBox(width: 4),
                                Text(
                                  'DEMO',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFBAE6FD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Village: ${widget.village} • Node ID: ${widget.nodeId}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card 1: Why this colour?
            _buildWhyThisColourCard(),

            const SizedBox(height: 14),

            // Card 2: Sanket Confidence
            _buildSanketConfidenceCard(),

            const SizedBox(height: 14),

            // Card 3: Source Digital Passport QR
            _buildPassportQrCard(),
          ],
        ),
      ),
    );
  }

  // Card 1: Why this colour?
  Widget _buildWhyThisColourCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D243F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E4068)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4A6E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Why this colour?',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'AI analysis based on latest sensor data',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF34D399)),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safe',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        Text(
                          'Total Score: $_totalScore/100',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4 Factor rows
          _buildFactorRow(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF064E3B),
            title: 'Latest test: Safe',
            sub: 'All key parameters within safe limits',
            score: '+0',
          ),
          const SizedBox(height: 8),

          _buildFactorRow(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF38BDF8),
            iconBg: const Color(0xFF0C4A6E),
            title: 'Flood flag active',
            sub: 'No flood risk detected',
            score: '+0',
          ),
          const SizedBox(height: 8),

          _buildFactorRow(
            icon: Icons.group_outlined,
            iconColor: const Color(0xFFC084FC),
            iconBg: const Color(0xFF3B1D48),
            title: 'Nearby cases (3, 7 days)',
            sub: 'Some nearby cases detected',
            score: '+15',
            scoreColor: const Color(0xFFF87171),
          ),
          const SizedBox(height: 8),

          _buildFactorRow(
            icon: Icons.cleaning_services_outlined,
            iconColor: const Color(0xFFFBBF24),
            iconBg: const Color(0xFF3B2E15),
            title: 'Cleaning gap $_cleaningGapDays days',
            sub: _cleaningGapDays > 30 ? 'Needs routine cleaning soon' : 'Recently disinfected',
            score: _cleaningGapDays > 30 ? '+10' : '+0',
            scoreColor: _cleaningGapDays > 30 ? const Color(0xFFF87171) : const Color(0xFF34D399),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String sub,
    required String score,
    Color scoreColor = const Color(0xFF38BDF8),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF112D4E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Sanket Confidence
  Widget _buildSanketConfidenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D243F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E4068)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C1D95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFC084FC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sanket Confidence',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      '1 of 4 signals agree → Single signal: retest',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'No field test saved yet (demo status)\nLast cleaned: 45 days ago',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), height: 1.25),
                    ),
                  ],
                ),
              ),

              // Circular Dial Ring (25%)
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: widget.confidencePercent / 100.0,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFF1E3A5F),
                      color: const Color(0xFFA855F7),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.confidencePercent}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const Text(
                          'Confidence',
                          style: TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mark cleaned today Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markCleanedToday,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Mark cleaned today',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Source Digital Passport QR
  Widget _buildPassportQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D243F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E4068)),
      ),
      child: Stack(
        children: [
          // Droplet ripple art on bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/images/water_drop_ripple.png',
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code Visual Box
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomPaint(
                  painter: _QrMatrixPainter(),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Source Digital Passport QR',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Print and fix at the water source. Villagers scan it to verify potability.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openVillagerView,
                      icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF38BDF8)),
                      label: const Text(
                        'Open villager view',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Procedural QR Code Matrix Painter
class _QrMatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double step = size.width / 13;

    // Corner squares
    void drawCorner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, step * 4, step * 4), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(x + step, y + step, step * 2, step * 2), whitePaint);
      canvas.drawRect(Rect.fromLTWH(x + (step * 1.5), y + (step * 1.5), step, step), paint);
    }

    drawCorner(0, 0);
    drawCorner(size.width - (step * 4), 0);
    drawCorner(0, size.height - (step * 4));

    // Fill inner pattern
    for (int i = 0; i < 13; i++) {
      for (int j = 0; j < 13; j++) {
        if ((i < 4 && j < 4) || (i > 8 && j < 4) || (i < 4 && j > 8)) continue;
        if ((i * 7 + j * 11 + 3) % 5 == 0 || (i + j) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(i * step, j * step, step * 0.9, step * 0.9), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
