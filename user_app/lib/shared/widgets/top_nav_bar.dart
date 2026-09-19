import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class TopNavBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onWhyUs;
  final VoidCallback onLocation;
  final VoidCallback onContact;
  final VoidCallback onSignIn;
  final bool isLoggedIn;
  final String? firstName;
  final VoidCallback? onProfile;
  final VoidCallback? onMenuTap;

  const TopNavBar({
    super.key,
    required this.onHome,
    required this.onAbout,
    required this.onWhyUs,
    required this.onLocation,
    required this.onContact,
    required this.onSignIn,
    required this.isLoggedIn,
    this.firstName,
    this.onProfile,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F29) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CenteredContent(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 12,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: onHome,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Garage',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Automotive',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu (desktop/tablet only)
              if (isDesktop || isTablet) ...[
                const SizedBox(width: 32),
                Expanded(
                  child: Row(
                    children: [
                      _navItem(context, 'Home', onHome, isDesktop),
                      _navItem(context, 'About', onAbout, isDesktop),
                      _navItem(context, 'Why Us', onWhyUs, isDesktop),
                      _navItem(context, 'Location', onLocation, isDesktop),
                      _navItem(context, 'Contact', onContact, isDesktop),
                    ],
                  ),
                ),
              ] else ...[
                const Spacer(),
                // Hamburger icon kwa mobile
                if (onMenuTap != null)
                  IconButton(
                    icon: const Icon(Icons.menu, size: 26),
                    onPressed: onMenuTap,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    tooltip: 'Menu',
                  ),
              ],

              // Auth button
              if (isLoggedIn)
                GestureDetector(
                  onTap: onProfile,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark
                          ? const Color(0xFF1A1F29)
                          : Colors.white,
                      child: Text(
                        (firstName?.isNotEmpty ?? false)
                            ? firstName![0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: onSignIn,
                  icon: const Icon(Icons.login, size: 16),
                  label: Text(
                    'Sign in',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 15 : 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
