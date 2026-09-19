import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/about/screens/about_screen.dart';
import '../../features/location/screens/location_screen.dart';
import '../../features/why_us/screens/why_us_screen.dart';
import '../../features/contact/screens/contact_screen.dart';

class QuickLinksBar extends StatelessWidget {
  const QuickLinksBar({super.key});

  @override
  Widget build(BuildContext context) {
    final links = [
      (Icons.location_on_outlined, 'Location', AppColors.primary,
          const LocationScreen()),
      (Icons.info_outline, 'About Us', AppColors.accent,
          const AboutScreen()),
      (Icons.star_outline, 'Why Us', AppColors.success,
          const WhyUsScreen()),
      (Icons.contact_support_outlined, 'Contact Us', const Color(0xFF25D366),
          const ContactScreen()),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: links.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, label, color, screen) = links[i];
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen)),
            child: Container(
              width: 95,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F29) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: color.withValues(alpha: 0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
