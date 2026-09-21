import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String _filter = "ALL";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminBookingAPI.list(
        status: _filter == "ALL" ? null : _filter,
      );
      if (mounted) setState(() { _bookings = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(dynamic b, String newStatus) async {
    try {
      final res = await AdminBookingAPI.updateStatus(
        bookingId: b["id"] as int,
        status: newStatus,
      );
      if (mounted && res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status imebadilishwa: $newStatus"),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip("ALL"),
                  _chip("PENDING"),
                  _chip("ACCEPTED"),
                  _chip("IN_PROGRESS"),
                  _chip("COMPLETED"),
                  _chip("CANCELLED"),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Text("Hakuna bookings",
                            style: GoogleFonts.poppins()),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _bookings.length,
                          itemBuilder: (_, i) => _card(_bookings[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == label,
        onSelected: (_) {
          setState(() => _filter = label);
          _load();
        },
      ),
    );
  }

  Widget _card(dynamic b) {
    final status = (b["status"] ?? "").toString();
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    b["booking_number"]?.toString() ?? "—",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row("Mteja", b["customer_name"]?.toString() ?? "—"),
            _row("Gari", b["vehicle_name"]?.toString() ?? "—"),
            _row("Service", b["service_name"]?.toString() ?? "—"),
            _row("Fundi", b["mechanic_name"]?.toString() ?? "Hajapangwa"),
            _row("Tarehe", "${b["scheduled_date"]} ${b["scheduled_time"] ?? ""}"),
            _row("Total", "TSh ${b["total_price"] ?? "0"}"),
            _row("Deposit", "TSh ${b["deposit_amount"] ?? "0"}"),
            _row("Payment", b["payment_status"]?.toString() ?? "UNPAID"),
            if (status == "PENDING") ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text("Kubali"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus(b, "ACCEPTED"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Kataa"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => _updateStatus(b, "REJECTED"),
                    ),
                  ),
                ],
              ),
            ],
            if (status == "ACCEPTED" || status == "CONFIRMED") ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text("Anza Kazi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _updateStatus(b, "IN_PROGRESS"),
                ),
              ),
            ],
            if (status == "IN_PROGRESS") ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text("Kamilisha Kazi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _updateStatus(b, "COMPLETED"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text("$label:",
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case "PENDING":
        return Colors.orange;
      case "ACCEPTED":
      case "CONFIRMED":
        return Colors.blue;
      case "IN_PROGRESS":
        return Colors.purple;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
