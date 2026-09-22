import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  String _fmtPrice(dynamic value) {
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

  String _formatDays(dynamic days) {
    if (days is! List || days.isEmpty) return '';
    const map = {
      'MON': 'Jtatu', 'TUE': 'Jnne', 'WED': 'Jtano',
      'THU': 'Alh', 'FRI': 'Ijm', 'SAT': 'Jmos', 'SUN': 'Jpil',
    };
    return days.map((d) => map[d.toString()] ?? d.toString()).join(', ');
  }

  String _formatTime(dynamic t) {
    if (t == null) return '';
    final s = t.toString();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final name = (service['name'] ?? 'Service').toString();
    final desc = (service['description'] ?? '').toString();
    final price = service['base_price'] ?? service['price'];
    final image = (service['image'] ?? '').toString();
    final category = (service['category_name'] ?? '').toString();
    final days = _formatDays(service['available_days']);
    final startTime = _formatTime(service['start_time']);
    final endTime = _formatTime(service['end_time']);
    final hasVideo = (service['video'] ?? '').toString().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (kama ipo)
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: const Center(
                      child: Icon(Icons.build, size: 40, color: AppColors.primary),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Video badge
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (hasVideo)
                        const Icon(Icons.videocam, size: 18, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if (desc.isNotEmpty)
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Siku
                  if (days.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            days,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Muda
                  if (startTime.isNotEmpty && endTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '$startTime - $endTime',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Price + Book button
                  Row(
                    children: [
                      if (price != null)
                        Text(
                          'TSh ${_fmtPrice(price)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Book',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}
