import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/auth_state.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/spare_parts/screens/spare_parts_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/mechanics/screens/mechanics_screen.dart';
import '../../features/diagnosis/screens/diagnosis_screen.dart';
import '../../features/obd/screens/obd_scanner_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/about/screens/about_screen.dart';
import '../../features/location/screens/location_screen.dart';
import '../../features/contact/screens/contact_screen.dart';
import '../../features/why_us/screens/why_us_screen.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _comingSoon(BuildContext context, String title) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthState.instance,
      builder: (context, _) {
        final loggedIn = AuthState.instance.isLoggedIn;
        final user = AuthState.instance.user;
        final firstName = user?['first_name']?.toString() ?? 'User';

        return Drawer(
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: loggedIn
                            ? Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loggedIn
                            ? 'Welcome, $firstName'
                            : AppConstants.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loggedIn
                            ? (user?['email']?.toString() ?? '')
                            : AppConstants.appTagline,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _item(Icons.home_outlined, 'Home',
                          () => Navigator.pop(context)),
                      _item(Icons.build_outlined, 'Services',
                          () => _push(context, const ServicesScreen())),
                      _item(Icons.settings_outlined, 'Spare Parts',
                          () => _push(context, const SparePartsScreen())),
                      _item(Icons.engineering_outlined, 'Find Mechanics',
                          () => _push(context, const MechanicsScreen())),
                      if (loggedIn) ...[
                        _item(Icons.event_note_outlined, 'My Bookings',
                            () => _push(context, const MyBookingsScreen())),
                        _item(Icons.chat_bubble_outline, 'Messages',
                            () => _push(context, const ChatListScreen())),
                        _item(Icons.bluetooth_searching, 'AI Car Scanner (OBD)',
                            () => _push(context, const ObdScannerScreen())),
                      ],
                      _item(Icons.psychology_outlined, 'AI Diagnosis',
                          () => _push(context, const DiagnosisScreen())),
                      _item(Icons.newspaper_outlined, 'News',
                          () => _push(context, const NewsScreen())),
                      const Divider(height: 24, indent: 16, endIndent: 16),
                      if (loggedIn) ...[
                        const Divider(height: 24, indent: 16, endIndent: 16),
                        _item(Icons.account_balance_wallet_outlined, 'Wallet',
                            () => _push(context, const WalletScreen())),
                        _item(Icons.receipt_long, 'Historia ya Malipo',
                            () => _push(context, const PaymentHistoryScreen())),
                        _item(Icons.person_outline, 'Profile',
                            () => _push(context, const ProfileScreen())),
                      ],
                      _item(Icons.info_outline, 'About Us',
                          () => _push(context, const AboutScreen())),
                      _item(Icons.location_on_outlined, 'Location',
                          () => _push(context, const LocationScreen())),
                      _item(Icons.contact_support_outlined, 'Contact Us',
                          () => _push(context, const ContactScreen())),
                      _item(Icons.star_outline, 'Why Us',
                          () => _push(context, const WhyUsScreen())),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: loggedIn
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            await AuthState.instance.logout();
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text('Logout',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(Icons.login, size: 18),
                          label: Text('Login / Sign up',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
