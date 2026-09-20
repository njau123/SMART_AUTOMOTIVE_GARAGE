import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/auth_state.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/hero_dashboard.dart';
import '../../../shared/widgets/quick_action.dart';
import '../../../shared/widgets/scrolling_ticker.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../services/screens/services_screen.dart';
import '../../spare_parts/screens/spare_parts_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../notifications/screens/notification_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  Map<String, dynamic>? _user;
  List<dynamic> _ads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AuthAPI.getProfile(),
        PublicAPI.getAdvertisements(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as Map<String, dynamic>;
        _ads = results[1] as List<dynamic>;
        _loading = false;
      });
      await AuthState.instance.init();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _firstName {
    final f = _user?['first_name']?.toString() ?? '';
    return f.isEmpty ? 'Driver' : f;
  }

  Map<String, dynamic>? get _vehicle {
    final v = _user?['vehicle'];
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String? get _vehicleName {
    final v = _vehicle;
    if (v == null) return null;
    final make = v['make']?.toString() ?? '';
    final model = v['model']?.toString() ?? '';
    final name = '$make $model'.trim();
    return name.isEmpty ? null : name;
  }

  List<String> get _tickerMessages {
    final msgs = <String>[];
    msgs.add('Welcome to Smart Automotive Garage');
    for (final a in _ads) {
      if (a is Map) {
        final title = a['title']?.toString() ?? '';
        if (title.isNotEmpty) msgs.add(title);
      }
    }
    msgs.add('Book a mechanic, buy spare parts, diagnose your car');
    return msgs;
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              // Badge ya unread (baadaye tutaongeza real-time)
              Positioned(
                right: 6,
                top: 6,
                child: FutureBuilder<int>(
                  future: NotificationAPI.getUnreadCount(),
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 180, borderRadius: BorderRadius.all(Radius.circular(24))),
        SizedBox(height: 20),
        Skeleton(height: 40),
        SizedBox(height: 20),
        Row(children: [
          Expanded(child: Skeleton(height: 90)),
          SizedBox(width: 10),
          Expanded(child: Skeleton(height: 90)),
          SizedBox(width: 10),
          Expanded(child: Skeleton(height: 90)),
        ]),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 12),

        // Hero dashboard
        HeroDashboard(
          firstName: _firstName,
          vehicleName: _vehicleName,
          vehicleRegistration: _vehicle?['registration_number']?.toString(),
          imageUrl: _user?['profile_image_url']?.toString() ??
              _vehicle?['vehicle_image']?.toString(),
          onTap: () => _open(const ProfileScreen()),
        ),
        const SizedBox(height: 16),

        // Scrolling ticker
        if (_tickerMessages.isNotEmpty)
          ScrollingTicker(
            messages: _tickerMessages,
            icon: Icons.campaign_outlined,
          ),
        const SizedBox(height: 20),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon: Icons.build_outlined,
                  label: 'Services',
                  color: AppColors.primary,
                  onTap: () => _open(const ServicesScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.settings_outlined,
                  label: 'Spare Parts',
                  color: AppColors.accent,
                  onTap: () => _open(const SparePartsScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.newspaper_outlined,
                  label: 'News',
                  color: AppColors.success,
                  onTap: () => _open(const NewsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // My stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'My Account',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _statsCard(),
        ),
      ],
    );
  }

  Widget _statsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F29) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3038) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _statRow(Icons.person_outline, 'Email', _user?['email']?.toString() ?? '-'),
          const Divider(height: 20),
          _statRow(Icons.phone_outlined, 'Phone', _user?['phone_number']?.toString() ?? '-'),
          const Divider(height: 20),
          _statRow(Icons.directions_car_outlined, 'Vehicle',
              _vehicleName ?? 'Not registered'),
          const Divider(height: 20),
          _statRow(Icons.badge_outlined, 'Registration',
              _vehicle?['registration_number']?.toString() ?? '-'),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
