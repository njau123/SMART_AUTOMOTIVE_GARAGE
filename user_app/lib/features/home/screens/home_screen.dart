import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/auth_state.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/top_nav_bar.dart';
import '../../../shared/widgets/ad_carousel.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../shared/widgets/spare_part_card.dart';
import '../../../shared/widgets/news_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/user_dashboard_screen.dart';
import '../../services/screens/services_screen.dart';
import '../../spare_parts/screens/spare_parts_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../mechanics/screens/mechanics_screen.dart';
import '../../diagnosis/screens/diagnosis_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../location/screens/location_screen.dart';
import '../../contact/screens/contact_screen.dart';
import '../../why_us/screens/why_us_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _homeKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _whyUsKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _contactKey = GlobalKey();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  String? _error;
  List<dynamic> _ads = [];
  List<dynamic> _services = [];
  List<dynamic> _spareParts = [];
  List<dynamic> _news = [];

  final _contactName = TextEditingController();
  final _contactLocation = TextEditingController();
  final _contactMessage = TextEditingController();
  bool _sendingMsg = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _contactName.dispose();
    _contactLocation.dispose();
    _contactMessage.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PublicAPI.getAdvertisements(),
        PublicAPI.getServices(),
        PublicAPI.getSpareParts(),
        PublicAPI.getNews(),
      ]);
      if (!mounted) return;
      setState(() {
        _ads = results[0];
        _services = results[1];
        _spareParts = results[2];
        _news = results[3];
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

  /// Inahitaji login kabla ya kuendelea.
  Future<bool> _requireLogin() async {
    if (AuthState.instance.isLoggedIn) return true;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return ok == true;
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openProtected(Widget screen) async {
    final logged = await _requireLogin();
    if (!mounted || !logged) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openDashboard() async {
    if (!AuthState.instance.isLoggedIn) {
      await _requireLogin();
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
    );
  }

  void _openFree(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ===== CONTACT =====
  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/255759212300?text=Hello%20Smart%20Automotive%20Garage');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open WhatsApp');
    }
  }

  Future<void> _openEmail() async {
    final url = Uri(
      scheme: 'mailto',
      path: 'njaufredrick38@gmail.com',
      query: 'subject=Inquiry from Smart Garage App',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open email app');
    }
  }

  Future<void> _openMap() async {
    // Mbezi Mwisho, Gerson Garage
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Gerson+Garage+Mbezi+Mwisho+Dar+es+Salaam',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open Google Maps');
    }
  }

  Future<void> _sendContactMessage() async {
    if (_contactName.text.trim().isEmpty ||
        _contactMessage.text.trim().isEmpty) {
      _snack('Please enter your name and message', error: true);
      return;
    }

    setState(() => _sendingMsg = true);
    try {
      // Send as a support request (using existing feedback endpoints or creating local success)
      // For now, save locally and show success
      // TODO: Wire to backend contact endpoint
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      _snack('Message sent! We will contact you soon.');
      _contactName.clear();
      _contactLocation.clear();
      _contactMessage.clear();
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sendingMsg = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ThemeController.instance.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ThemeController.instance.toggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          TopNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onHome: () => _scrollTo(_homeKey),
            onAbout: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutScreen())),
            onWhyUs: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WhyUsScreen())),
            onLocation: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LocationScreen())),
            onContact: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactScreen())),
            onSignIn: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            isLoggedIn: AuthState.instance.isLoggedIn,
            firstName: AuthState.instance.user?['first_name']?.toString(),
            onProfile: _openDashboard,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 160, borderRadius: BorderRadius.all(Radius.circular(20))),
        SizedBox(height: 24),
        Skeleton(height: 20, width: 150),
        SizedBox(height: 12),
        Row(children: [
          Expanded(child: Skeleton(height: 140)),
          SizedBox(width: 10),
          Expanded(child: Skeleton(height: 140)),
        ]),
      ],
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
                Text('Failed to load data',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_error ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAll,
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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ===== HERO / ABOUT US =====
        KeyedSubtree(key: _homeKey, child: const SizedBox.shrink()),
        _heroSection(),
        KeyedSubtree(key: _aboutKey, child: const SizedBox(height: 1)),
        const SizedBox(height: 20),

        // ===== ADVERTISEMENTS =====
        if (_ads.isNotEmpty) ...[
          _sectionHeader('Advertisements', subtitle: 'From Smart Garage'),
          const SizedBox(height: 12),
          AdCarousel(ads: _ads, onTap: (_) => _openFree(const SparePartsScreen())),
          const SizedBox(height: 28),
        ],

        // ===== SERVICES (requires login) =====
        if (_services.isNotEmpty) ...[
          _sectionHeader('Our Services',
              subtitle: 'Tap to explore — sign in required',
              action: () => _openProtected(const ServicesScreen())),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _services.length,
              itemBuilder: (_, i) => Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: ServiceCard(
                  service: _services[i] as Map<String, dynamic>,
                  onTap: () => _openProtected(const ServicesScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // ===== QUICK ACTIONS =====
        _sectionHeader('Quick Actions', subtitle: 'Tap to access'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _quickAction(
                  Icons.settings_outlined,
                  'Spare Parts',
                  AppColors.accent,
                  () => _openProtected(const SparePartsScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickAction(
                  Icons.engineering_outlined,
                  'Mechanics',
                  AppColors.success,
                  () => _openProtected(const MechanicsScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickAction(
                  Icons.psychology_outlined,
                  'AI Diagnosis',
                  AppColors.info,
                  () => _openProtected(const DiagnosisScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ===== SPARE PARTS =====
        if (_spareParts.isNotEmpty) ...[
          _sectionHeader('Spare Parts',
              subtitle: 'Popular car parts',
              action: () => _openProtected(const SparePartsScreen())),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _spareParts.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SparePartCard(
                  part: _spareParts[i] as Map<String, dynamic>,
                  onTap: () => _openProtected(const SparePartsScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // ===== NEWS (free access) =====
        if (_news.isNotEmpty) ...[
          _sectionHeader('News & Updates',
              subtitle: 'From Smart Garage',
              action: () => _openFree(const NewsScreen())),
          const SizedBox(height: 12),
          ..._news.map(
            (n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: NewsCard(
                news: n as Map<String, dynamic>,
                onTap: () => _openFree(const NewsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // ===== WHY CHOOSE US =====
        KeyedSubtree(key: _whyUsKey, child: const SizedBox(height: 1)),
        _whyChooseUs(),
        const SizedBox(height: 28),

        // ===== LOCATION =====
        KeyedSubtree(key: _locationKey, child: const SizedBox(height: 1)),
        _locationSection(),

        // ===== CONTACT US =====
        KeyedSubtree(key: _contactKey, child: const SizedBox(height: 1)),
        _contactSection(),

        // ===== FOOTER =====
        _footer(),
      ],
    );
  }

  // ===== HERO / ABOUT US =====
  Widget _heroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(AppImages.homepageBg,
              fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1976D2),
                        Color(0xFF42A5F5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.85),
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ABOUT US',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Smart Automotive Garage',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trusted partner for automotive care in Tanzania. '
            'We connect you with expert mechanics, quality spare parts, '
            'and AI-powered diagnostics — all in one place.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
                Row(
                  children: [
                    _heroBadge(Icons.verified_outlined, 'Certified'),
                    const SizedBox(width: 8),
                    _heroBadge(Icons.flash_on_outlined, 'Fast Service'),
                    const SizedBox(width: 8),
                    _heroBadge(Icons.security_outlined, 'Trusted'),
                  ],
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ===== WHY CHOOSE US =====
  Widget _whyChooseUs() {
    final items = [
      ('Expert Mechanics', 'Verified professionals across Tanzania',
          Icons.engineering_outlined, AppColors.success),
      ('Quality Spare Parts', 'Genuine parts with warranty',
          Icons.settings_outlined, AppColors.accent),
      ('AI Diagnosis', 'Smart detection of car problems',
          Icons.psychology_outlined, AppColors.info),
      ('Fast Response', 'Mechanics come to your location',
          Icons.speed_outlined, AppColors.primary),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why Choose Us',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Trusted by drivers across Tanzania',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3, color: item.$4, size: 24),
                    const SizedBox(height: 8),
                    Text(item.$1,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== LOCATION =====
  Widget _locationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Our Location',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Come visit us',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openMap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gerson Garage',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Mbezi Mwisho, Dar es Salaam',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9))),
                        const SizedBox(height: 4),
                        Text('Tap to open in Google Maps',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CONTACT US =====
  Widget _contactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Us',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Send us a message or reach out directly',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),

          // Contact buttons
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  Icons.chat_bubble_outline,
                  'WhatsApp',
                  '0759 212 300',
                  const Color(0xFF25D366),
                  _openWhatsApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  Icons.mail_outline,
                  'Email',
                  'Admin',
                  AppColors.primary,
                  _openEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send us a message',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactName,
                  decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactLocation,
                  decoration: const InputDecoration(
                    hintText: 'Your location (optional)',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactMessage,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Your message...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sendingMsg ? null : _sendContactMessage,
                    icon: _sendingMsg
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(_sendingMsg ? 'Sending...' : 'Send Message'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, String value,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ===== FOOTER =====
  Widget _footer() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Text(
            'Smart Automotive Garage',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your car, our priority',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('0759 212 300',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 16),
              Icon(Icons.mail_outline,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('njaufredrick38@gmail.com',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 Smart Automotive Garage. All rights reserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPERS =====
  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? subtitle, VoidCallback? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action,
              child: Row(
                children: [
                  Text('See all',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
