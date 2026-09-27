import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class ServiceJobsScreen extends StatefulWidget {
  const ServiceJobsScreen({super.key});

  @override
  State<ServiceJobsScreen> createState() => _ServiceJobsScreenState();
}

class _ServiceJobsScreenState extends State<ServiceJobsScreen> {
  bool _loading = true;
  List<dynamic> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await MechanicAPI.getAvailableServiceJobs();
      if (mounted) setState(() { _jobs = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(dynamic j) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chukua kazi?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Mteja: ${j['user_name']}\nGari: ${j['vehicle']}\nLocation: ${j['service_address']}\n\nUna uhakika wa kuchukua kazi hii?',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Chukua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await MechanicAPI.acceptServiceJob(j['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umekubali kazi ✅'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openMaps(dynamic j) async {
    final lat = j['service_latitude'];
    final lng = j['service_longitude'];
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text('Service Jobs',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Hakuna kazi bado',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _jobs.length,
                    itemBuilder: (_, i) {
                      final j = _jobs[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.handyman, color: Colors.teal, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(j['service_name']?.toString() ?? 'Service',
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                                        Text(j['booking_number']?.toString() ?? '',
                                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)),
                                      ],
                                    ),
                                  ),
                                  Text('TSh ${(j['total_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _row(Icons.person, 'Mteja', j['user_name']?.toString() ?? '-'),
                              _row(Icons.phone, 'Simu', j['user_phone']?.toString() ?? '-'),
                              _row(Icons.directions_car, 'Gari', j['vehicle']?.toString() ?? '-'),
                              _row(Icons.location_on, 'Eneo', j['service_address']?.toString() ?? '-'),
                              if (j['scheduled_date'] != null)
                                _row(Icons.calendar_today, 'Tarehe', '${j['scheduled_date']} ${j['scheduled_time'] ?? ''}'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (j['service_latitude'] != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openMaps(j),
                                        icon: const Icon(Icons.map, size: 16),
                                        label: Text('Maps', style: GoogleFonts.poppins(fontSize: 12)),
                                      ),
                                    ),
                                  if (j['service_latitude'] != null) const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _accept(j),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: Text('Chukua Kazi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          SizedBox(width: 60, child: Text('$label:', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12))),
        ],
      ),
    );
  }
}
