import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/admin_drawer.dart';
import '../../ads/screens/ads_screen.dart';
import '../../news/screens/admin_news_screen.dart';
import '../../mechanics/screens/admin_mechanics_screen.dart';
import '../../spare_parts/screens/admin_spare_parts_screen.dart';
import '../../services/screens/admin_services_screen.dart';
import '../../payments/screens/admin_payments_screen.dart';
import '../../users/screens/admin_users_screen.dart';
import '../../bookings/screens/admin_bookings_screen.dart';
import '../../notifications/screens/admin_notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminAPI.getStats();
      if (!mounted) return;
      setState(() {
        _stats = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  int _intVal(String key) {
    final v = _stats?[key];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  double _doubleVal(String key) {
    final v = _stats?[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(_error ?? 'Error',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, Admin',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Manage your garage — see stats below',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats grid
        Text('Overview',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard(
              Icons.people_outline,
              'Users',
              '${_intVal('total_users')}',
              AppColors.primary,
              onTap: () => _push(const UsersScreen()),
            ),
            _statCard(
              Icons.engineering_outlined,
              'Mechanics',
              '${_intVal('total_mechanics')}',
              AppColors.accent,
              onTap: () => _push(const MechanicsScreen()),
            ),
            _statCard(
              Icons.settings_outlined,
              'Spare Parts',
              '${_intVal('total_spare_parts')}',
              AppColors.success,
              onTap: () => _push(const AdminSparePartsScreen()),
            ),
            _statCard(
              Icons.build_outlined,
              'Services',
              '${_intVal('total_services')}',
              AppColors.info,
              onTap: () => _push(const AdminServicesScreen()),
            ),
            _statCard(
              Icons.newspaper_outlined,
              'News',
              '${_intVal('total_news')}',
              AppColors.primaryLight,
              onTap: () => _push(const NewsScreen()),
            ),
            _statCard(
              Icons.campaign_outlined,
              'Ads',
              '${_intVal('total_ads')}',
              AppColors.accentLight,
              onTap: () => _push(const AdsScreen()),
            ),
            _statCard(
              Icons.event_available_outlined,
              'Bookings',
              '${_intVal('total_bookings')}',
              AppColors.primaryDark,
              onTap: () => _push(const AdminBookingsScreen()),
            ),
            _statCard(
              Icons.payments_outlined,
              'Revenue',
              'TSh ${_fmt(_doubleVal('total_revenue'))}',
              AppColors.success,
              small: true,
              onTap: () => _push(const PaymentsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick actions
        Text('Quick Actions',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _actionTile(
          Icons.campaign_outlined,
          'Manage Advertisements',
          'Upload images, audio, or video',
          AppColors.accent,
          () => _push(const AdsScreen()),
        ),
        _actionTile(
          Icons.newspaper_outlined,
          'Post News',
          'Share updates with users',
          AppColors.primary,
          () => _push(const NewsScreen()),
        ),
        _actionTile(
          Icons.engineering_outlined,
          'Manage Mechanics',
          'Available / Unavailable',
          AppColors.success,
          () => _push(const MechanicsScreen()),
        ),
        _actionTile(
          Icons.payment_outlined,
          'Verify Payments',
          'Confirm user payments',
          AppColors.info,
          () => _push(const PaymentsScreen()),
        ),
        _actionTile(
          Icons.notifications_active_outlined,
          'Send Notification',
          'Broadcast to all users',
          AppColors.warning,
          () => _push(const NotificationsScreen()),
        ),
        _actionTile(
          Icons.people_outline,
          'View Users',
          'List of registered users',
          AppColors.primaryDark,
          () => _push(const UsersScreen()),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color,
      {bool small = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: small ? 15 : 20,
                      fontWeight: FontWeight.bold,
                    )),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
