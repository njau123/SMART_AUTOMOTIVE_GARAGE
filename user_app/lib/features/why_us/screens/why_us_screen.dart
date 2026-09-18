
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class WhyUsScreen extends StatelessWidget {
  const WhyUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Why Us")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Kwa Nini Utuchague?", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _card(Icons.verified_outlined, "Mafundi Waliothibitishwa", "Kila fundi anapitia uthibitisho mkali.", Colors.blue),
              _card(Icons.speed_outlined, "Huduma ya Haraka", "Tunakuunganisha na fundi aliye karibu.", Colors.orange),
              _card(Icons.security_outlined, "Malipo Salama", "Malipo yote yanathibitishwa na admin.", Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
