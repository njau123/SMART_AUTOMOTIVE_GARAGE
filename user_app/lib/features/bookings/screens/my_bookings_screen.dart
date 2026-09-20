import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await BookingAPI.myBookings();
      if (mounted) setState(() { _bookings = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'ARRIVING': return Colors.purple;
      case 'IN_PROGRESS': return Colors.indigo;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Bookings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _bookings.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (_, i) => _card(_bookings[i]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error ?? 'Error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Jaribu Tena')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Hakuna bookings bado',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Book huduma kutoka kwa mechanics',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _card(dynamic b) {
    final status = b['status']?.toString() ?? 'PENDING';
    final color = _statusColor(status);
    final mechanicName = b['mechanic_name']?.toString() ?? 'Inasubiri';
    final serviceName = b['service_name']?.toString() ?? 'Huduma';
    final scheduled = b['scheduled_date']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                bookingId: b['id'] as int,
              ),
            ),
          );
          if (result == true) _load();
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.build_circle, color: color, size: 22),
        ),
        title: Text(b['booking_number']?.toString() ?? 'Booking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName,
                style: GoogleFonts.poppins(fontSize: 12)),
            Text('Mechanic: $mechanicName',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            if (scheduled.isNotEmpty)
              Text('Tarehe: $scheduled',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.replaceAll('_', ' '),
            style: GoogleFonts.poppins(
                fontSize: 9, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    );
  }
}
