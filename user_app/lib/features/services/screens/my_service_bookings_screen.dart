import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'service_tracking_screen.dart';

class MyServiceBookingsScreen extends StatefulWidget {
  const MyServiceBookingsScreen({super.key});

  @override
  State<MyServiceBookingsScreen> createState() => _MyServiceBookingsScreenState();
}

class _MyServiceBookingsScreenState extends State<MyServiceBookingsScreen> {
  bool _loading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ServiceBookingAPI.myBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING_PAYMENT': return Colors.orange;
      case 'DEPOSIT_PAID': return Colors.blue;
      case 'CONFIRMED': return Colors.indigo;
      case 'IN_PROGRESS': return Colors.deepOrange;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING_PAYMENT': return 'Inasubiri malipo';
      case 'DEPOSIT_PAID': return 'Deposit imelipwa';
      case 'CONFIRMED': return 'Imethibitishwa';
      case 'IN_PROGRESS': return 'Inafanyika';
      case 'COMPLETED': return 'Imekamilika';
      case 'CANCELLED': return 'Imefutwa';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Service Zangu',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman_outlined, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Hauna service booking bado',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _bookings.length,
                    itemBuilder: (_, i) {
                      final b = _bookings[i];
                      final s = b['status']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceTrackingScreen(
                                  bookingId: b['id'] as int,
                                  bookingNumber: b['booking_number']?.toString() ?? '',
                                  serviceName: b['service_name']?.toString() ?? 'Service',
                                ),
                              ),
                            ).then((_) => _load());
                          },
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
                                        color: _statusColor(s).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.handyman,
                                          color: _statusColor(s), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b['service_name']?.toString() ?? 'Service',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14, fontWeight: FontWeight.w700)),
                                          Text(b['booking_number']?.toString() ?? '',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(s),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(_statusLabel(s),
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text('TSh ${NumberFormat("#,##0").format(b['deposit_amount'] ?? 0)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                    const Spacer(),
                                    Text(b['created_at']?.toString().substring(0, 10) ?? '',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
