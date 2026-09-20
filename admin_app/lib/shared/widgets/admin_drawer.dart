import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/auth_state.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/ads/screens/ads_screen.dart';
import '../../features/news/screens/admin_news_screen.dart';
import '../../features/mechanics/screens/admin_mechanics_screen.dart';
import '../../features/payments/screens/admin_payments_screen.dart';
import '../../features/spare_parts/screens/admin_spare_parts_screen.dart';
import '../../features/bookings/screens/admin_bookings_screen.dart';
import '../../features/users/screens/admin_users_screen.dart';
import '../../features/notifications/screens/admin_notifications_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/contact/screens/admin_contact_screen.dart';
import '../../features/orders/screens/admin_orders_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdminAuthState.instance,
      builder: (context, _) {
        final user = AdminAuthState.instance.user;
        final firstName = user?['first_name']?.toString() ?? 'Admin';

        return Drawer(
          backgroundColor: Colors.white,
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
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'A',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Admin: $firstName',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?['email']?.toString() ?? '',
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
                      _item(Icons.dashboard_outlined, 'Dashboard',
                          () => _push(context, const AdminDashboardScreen())),
                      _item(Icons.campaign_outlined, 'Advertisements',
                          () => _push(context, const AdsScreen())),
                      _item(Icons.newspaper_outlined, 'News',
                          () => _push(context, const NewsScreen())),
                      _item(Icons.engineering_outlined, 'Mechanics',
                          () => _push(context, const MechanicsScreen())),
                      _item(Icons.payment_outlined, 'Payments',
                          () => _push(context, const PaymentsScreen())),
                      _item(Icons.inventory_2_outlined, 'Spare Parts',
                          () => _push(context, const AdminSparePartsScreen())),
                      _item(Icons.shopping_bag_outlined, 'Orders',
                          () => _push(context, const AdminOrdersScreen())),
                      _item(Icons.people_outline, 'Users',
                          () => _push(context, const UsersScreen())),
                      _item(Icons.mail_outline, 'Contact Messages',
                          () => _push(context, const AdminContactScreen())),
                      _item(Icons.notifications_active_outlined,
                          'Notifications',
                          () => _push(context, const NotificationsScreen())),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AdminAuthState.instance.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text('Logout',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
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
        style:
            GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
