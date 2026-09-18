
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});
  static const double _lat = -6.7515;
  static const double _lng = 39.2047;

  Future<void> _openMaps() async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$_lat,$_lng");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Our Location")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 220, width: double.infinity, color: const Color(0xFFE8F0FE),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 60),
                      SizedBox(height: 8),
                      Text("Maji Chumvi, Dar es Salaam"),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Automotive Smart Garage", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Tupo Maji Chumvi, Dar es Salaam", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text("Fungua Google Maps"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
