import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatefulWidget {
  final String userName;
  final String userId;
  final String userRole;
  final Function(String item)? onItemSelected;

  const AppSidebar({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
    this.userRole = 'ASHA Worker',
    this.onItemSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String _activeItem = 'डॅशबोर्ड';

  void _handleItemTap(String item) {
    setState(() {
      _activeItem = item;
    });

    Navigator.of(context).pop(); // Close drawer

    if (widget.onItemSelected != null) {
      widget.onItemSelected!(item);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.alertRed, size: 22),
            SizedBox(width: 8),
            Text(
              'लॉग आऊट / Log Out',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkSlate, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'तुम्हाला सध्याचे सत्र समाप्त करून बाहेर पडायचे आहे का?\n(Are you sure you want to end your current session?)',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('रद्द करा (Cancel)', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('लॉग आऊट करा (Log Out)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.zero,
          border: Border(
            right: BorderSide(color: AppTheme.cyan, width: 2.0),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Header with Logo, Title, and Close Button
              _buildTopHeader(),

              const SizedBox(height: 12),

              // 2. User Profile Card (Strict sharp edges)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: _buildProfileCard(),
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0x3300BCD4), height: 1, thickness: 1),
              const SizedBox(height: 8),

              // 3. Scrollable Working Menu Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  children: [
                    _buildMenuItem(
                      title: 'डॅशबोर्ड (Dashboard)',
                      keyName: 'Dashboard',
                      icon: Icons.dashboard_outlined,
                      iconColor: AppTheme.cyan,
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'जल स्त्रोत नकाशा (Water Map)',
                      keyName: 'Map',
                      icon: Icons.map_outlined,
                      iconColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: widget.userRole == 'Medical Officer'
                          ? 'डॉक्टर ट्रायज (Doctor Triage)'
                          : 'आवाज रुग्ण नोंद (Voice Cases)',
                      keyName: 'Voice',
                      icon: Icons.mic_none_outlined,
                      iconColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'IoT पाणी टेस्ट (IoT Testing)',
                      keyName: 'IoT Test',
                      icon: Icons.sensors_outlined,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'सर्व जल स्त्रोत (All Sources)',
                      keyName: 'All sources',
                      icon: Icons.water_drop_outlined,
                      iconColor: AppTheme.cyan,
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'पूर्वसूचना (Early Signal & Risk)',
                      keyName: 'Early signal (7 days)',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF22C55E),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'साप्ताहिक अहवाल (Weekly Report)',
                      keyName: 'Weekly report',
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'हवामान अंदाज (IMD Weather)',
                      keyName: 'हवामान (IMD Weather)',
                      icon: Icons.cloud_outlined,
                      iconColor: const Color(0xFF00BCD4),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'JJM ग्राम माहिती (JJM Village Info)',
                      keyName: 'JJM ग्राम माहिती',
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF818CF8),
                    ),
                    const SizedBox(height: 4),

                    _buildMenuItem(
                      title: 'सेटिंग्ज (Settings)',
                      keyName: 'Settings',
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x3300BCD4), height: 1, thickness: 1),

              // 4. Log out Bottom Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: _buildLogoutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Header with Logo, Title, and Close Button
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/app-logo.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'जलसंकेत (JalSanket)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${widget.userRole.toUpperCase()} PORTAL',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cyan,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // 2. User Profile Card
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C386E),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppTheme.cyan.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.6)),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${widget.userId} • ${widget.userRole}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Menu Item Tile
  Widget _buildMenuItem({
    required String title,
    required String keyName,
    required IconData icon,
    required Color iconColor,
  }) {
    final bool isActive = _activeItem == keyName || _activeItem == title;
    return InkWell(
      onTap: () => _handleItemTap(keyName),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isActive ? AppTheme.cyan : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppTheme.cyan : iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                color: AppTheme.cyan,
              ),
          ],
        ),
      ),
    );
  }

  // 4. Log Out Button
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _confirmLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFEF4444), width: 1.0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'बाहेर पडा (Log Out)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
