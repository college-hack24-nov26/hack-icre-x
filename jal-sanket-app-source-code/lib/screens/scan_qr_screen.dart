import 'package:flutter/material.dart';
import 'source_passport_dialog.dart';

class ScanQrScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const ScanQrScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _openPassport(String name, String village, String nodeId, int score, int conf, int cleanGap) {
    SourcePassportSheet.show(
      context,
      sourceName: name,
      village: village,
      nodeId: nodeId,
      totalScore: score,
      confidencePercent: conf,
      cleaningGapDays: cleanGap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07192E),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildTopHeader(),

            const SizedBox(height: 10),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // Scanner Box Card
                    _buildScannerCard(),

                    const SizedBox(height: 20),

                    // Divider title: QUICK DEMO PASSPORT SELECTORS
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFF1E3A5F), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'QUICK DEMO PASSPORT SELECTORS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFF1E3A5F), thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2x2 Grid of Quick Selectors
                    _buildSelectorsGrid(),

                    const SizedBox(height: 16),

                    // Droplet graphic at bottom right
                    Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset(
                        'assets/images/water_drop_ripple.png',
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Scan QR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SOURCE PASSPORT VERIFICATION',
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

          // Droplet graphic
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
        ],
      ),
    );
  }

  // Scanner Box Card
  Widget _buildScannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2138),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF163E66)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C3D6A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF38BDF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Scan Source Passport QR Code',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Point your camera at the Source Passport QR code affixed to the well or handpump.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Viewfinder Box
          Center(
            child: SizedBox(
              width: 230,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle inner camera viewport
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07192E).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 130,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Animated Horizontal Scan Line
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (ctx, child) {
                      return Positioned(
                        top: 220 * _scanAnimation.value,
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF38BDF8),
                                Color(0xFF38BDF8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Corner Brackets
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ViewfinderCornersPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Callout info box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2B48),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E4068)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure good lighting and keep the QR code within the frame',
                    style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2x2 Grid of Quick Selectors
  Widget _buildSelectorsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSelectorCard(
                title: 'Pimpri Well 1',
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF38BDF8),
                iconBg: const Color(0xFF0C4A6E),
                onTap: () => _openPassport('Pimpri Well 1', 'Pimpri', '01', 25, 25, 45),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectorCard(
                title: 'Pimpri Handpump',
                icon: Icons.precision_manufacturing_rounded,
                iconColor: const Color(0xFF34D399),
                iconBg: const Color(0xFF064E3B),
                onTap: () => _openPassport('Pimpri Handpump', 'Pimpri', '02', 15, 35, 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSelectorCard(
                title: 'Kasba Spring',
                icon: Icons.local_drink_rounded,
                iconColor: const Color(0xFFC084FC),
                iconBg: const Color(0xFF3B1D48),
                onTap: () => _openPassport('Kasba Spring', 'Kasba', '03', 0, 90, 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectorCard(
                title: 'Kasba Tap',
                icon: Icons.water_rounded,
                iconColor: const Color(0xFFFBBF24),
                iconBg: const Color(0xFF3B2E15),
                onTap: () => _openPassport('Kasba Tap', 'Kasba', '04', 0, 95, 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0C243E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E4068)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Viewfinder 4 Corner Brackets
class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 28;
    final double w = size.width;
    final double h = size.height;

    // Top-Left ┌
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-Right ┐
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLen, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    // Bottom-Left └
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLen), paint);

    // Bottom-Right ┘
    canvas.drawLine(Offset(w, h), Offset(w - cornerLen, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
