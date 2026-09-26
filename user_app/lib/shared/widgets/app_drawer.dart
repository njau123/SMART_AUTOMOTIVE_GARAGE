import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../core/localization/app_localizations.dart';
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

  // ignore: unused_element
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

        final t = AppLocalizations.of(context).t;
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
                      _item(Icons.home_outlined, t('home'),
                          () => Navigator.pop(context)),
                      _item(Icons.build_outlined, t('services'),
                          () => _push(context, const ServicesScreen())),
                      _item(Icons.settings_outlined, t('spare_parts'),
                          () => _push(context, const SparePartsScreen())),
                      _item(Icons.engineering_outlined, t('mechanics'),
                          () => _push(context, const MechanicsScreen())),
                      if (loggedIn) ...[
                        _item(Icons.event_note_outlined, t('bookings'),
                            () => _push(context, const MyBookingsScreen())),
                        _item(Icons.chat_bubble_outline, t('chat'),
                            () => _push(context, const ChatListScreen())),
                        _item(Icons.bluetooth_searching, 'AI Car Scanner (OBD)',
                            () => _push(context, const ObdScannerScreen())),
                      ],
                      _item(Icons.psychology_outlined, t('ai_diagnosis'),
                          () => _push(context, const DiagnosisScreen())),
                      _item(Icons.newspaper_outlined, 'News',
                          () => _push(context, const NewsScreen())),
                      const Divider(height: 24, indent: 16, endIndent: 16),
                      if (loggedIn) ...[
                        const Divider(height: 24, indent: 16, endIndent: 16),
                        _item(Icons.account_balance_wallet_outlined, t('wallet'),
                            () => _push(context, const WalletScreen())),
                        _item(Icons.receipt_long, 'Historia ya Malipo',
                            () => _push(context, const PaymentHistoryScreen())),
                        _item(Icons.person_outline, t('profile'),
                            () => _push(context, const ProfileScreen())),
                      ],
                      _item(Icons.language, t('language'),
                          () => _showLanguagePicker(context)),
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
                          label: Text(t('logout'),
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
                          label: Text(t('login'),
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

  void _showLanguagePicker(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.language, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Chagua Lugha / Select Language',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langOption(ctx, langProvider, 'sw', 'Kiswahili', '🇹🇿'),
              const SizedBox(height: 8),
              _langOption(ctx, langProvider, 'en', 'English', '🇬🇧'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Funga / Close',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _langOption(
    BuildContext ctx,
    LanguageProvider provider,
    String code,
    String label,
    String flag,
  ) {
    final isSelected = provider.locale.languageCode == code;
    return InkWell(
      onTap: () async {
        await provider.changeLanguage(code);
        if (ctx.mounted) Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
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
