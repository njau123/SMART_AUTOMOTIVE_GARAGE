
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("About Us")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.build_circle_outlined,
                        color: Colors.white, size: 60),
                    const SizedBox(height: 12),
                    Text(AppConstants.appName,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(AppConstants.appTagline,
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sec("Nani Sisi", "Automotive Smart Garage ni kampuni ya Tanzania inayotoa huduma za ufundi wa magari kwa kiwango cha kimataifa."),
              _sec("Dhamira Yetu", "Kuhakikisha kila dereva Tanzania anapata huduma bora za ufundi kwa haraka na kwa bei nafuu."),
              _sec("Maono Yetu", "Kuwa jukwaa la kwanza la kidijitali Tanzania linalounganisha mifumo yote ya ufundi wa magari."),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sec(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
