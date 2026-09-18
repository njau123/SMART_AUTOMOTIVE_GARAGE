import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SparePartCard extends StatelessWidget {
  final Map<String, dynamic> part;
  final VoidCallback? onTap;

  const SparePartCard({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (part['name'] ?? 'Part').toString();
    final price = part['price'];
    final image = part['main_image']?.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Container(
                height: 110,
                width: double.infinity,
                color: AppColors.surfaceAlt,
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textMuted,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (price != null)
                    Text(
                      'TSh ${_formatPrice(price)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic value) {
    try {
      final n = double.parse(value.toString());
      return n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    } catch (_) {
      return value.toString();
    }
  }
}
