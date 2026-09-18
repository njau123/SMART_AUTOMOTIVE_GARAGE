import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Consistent "Title + subtitle" header used above every section.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing, this.titleSize = 20});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: titleSize, fontWeight: FontWeight.bold, color: textColor)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
