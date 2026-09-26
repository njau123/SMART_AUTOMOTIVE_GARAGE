import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../jobs/screens/job_list_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../reviews/screens/reviews_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../requests/screens/requests_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileAPI.getProfile();
      setState(() => _profile = data);
    } catch (e) {
      // silently fail
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileImagePath == null) return null;
    if (_profileImagePath!.startsWith('http')) {
      return NetworkImage(_profileImagePath!);
    }
    return FileImage(File(_profileImagePath!));
  }

  Future<void> _pickAndUploadProfile() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImagePath = image.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = _profile?['business_name'] ?? 'Mechanic';
    final regNumber = _profile?['verification_documents']?['registration_number'] 
        ?? _profile?['registration_number'] 
        ?? 'Haijawekwa';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _pickAndUploadProfile,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: _getProfileImage(),
                child: _profileImagePath == null ? const Icon(Icons.person, color: AppTheme.primary) : null,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, color: AppTheme.primary)),
                  SizedBox(height: 8),
                  Text('Mechanic Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ),
              ListTile(leading: const Icon(Icons.home, color: Colors.white70), title: const Text('Dashboard', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.notifications_active, color: Colors.white70), title: const Text('Requests Mpya', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestsScreen())); }),
              ListTile(leading: const Icon(Icons.work, color: Colors.white70), title: const Text('Available Jobs', style: TextStyle(color: Colors.white)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen()))),
              ListTile(leading: const Icon(Icons.chat, color: Colors.white70), title: const Text('Messages', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())); }),
              ListTile(leading: const Icon(Icons.logout, color: Colors.white70), title: const Text('Logout', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.backgroundMechanic),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Welcome Expert Mechanic $businessName!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Reg No: $regNumber', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Available for jobs', style: TextStyle(color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 30),
          Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildActionCard(Icons.work_outline, 'View Jobs', 'Browse available jobs', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListScreen()));
              }),
              _buildActionCard(Icons.payments, 'Earnings', 'Your income', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
              }),
              _buildActionCard(Icons.rate_review, 'Reviews', 'Client feedback', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
              }),
              _buildActionCard(Icons.settings, 'Settings', 'App settings', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: AppTheme.primary),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}
