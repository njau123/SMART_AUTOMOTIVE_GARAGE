import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminServiceBookingsScreen extends StatefulWidget {
  const AdminServiceBookingsScreen({super.key});

  @override
  State<AdminServiceBookingsScreen> createState() =>
      _AdminServiceBookingsScreenState();
}

class _AdminServiceBookingsScreenState
    extends State<AdminServiceBookingsScreen> {
  bool _loading = true;
  List<dynamic> _bookings = [];
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AdminAPI.getServiceBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'ALL') return _bookings;
    return _bookings
        .where((b) => b['status']?.toString() == _filter)
        .toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING_PAYMENT':
        return Colors.orange;
      case 'DEPOSIT_PAID':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.indigo;
      case 'IN_PROGRESS':
        return Colors.deepOrange;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _verifyPayment(dynamic b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thibitisha malipo?'),
        content: Text(
            'Thibitisha kwamba ${b['user_email']} amelipa deposit ya TSh ${NumberFormat("#,##0").format(b['deposit_amount'])}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thibitisha',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminAPI.verifyServiceBooking(b['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Malipo yamethibitishwa ✅'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _setAppointment(dynamic b) async {
    DateTime selectedDate =
        DateTime.now().add(const Duration(days: 1));
    int etaHours = 0;
    int etaMinutes = 30;
    String adminNotes = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set Appointment',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarehe:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('ETA (kama mobile service):',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: etaHours > 0
                                ? () => setDialogState(() => etaHours--)
                                : null,
                          ),
                          Text('${etaHours}h',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: etaHours < 12
                                ? () => setDialogState(() => etaHours++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: etaMinutes >= 15
                                ? () => setDialogState(
                                    () => etaMinutes -= 15)
                                : null,
                          ),
                          Text('${etaMinutes}m',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: etaMinutes < 45
                                ? () => setDialogState(
                                    () => etaMinutes += 15)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => adminNotes = v,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Maelezo ya admin',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hifadhi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final timeStr =
          '${etaHours.toString().padLeft(2, '0')}:${etaMinutes.toString().padLeft(2, '0')}';
      await AdminAPI.setServiceAppointment(
        bookingId: b['id'] as int,
        appointmentDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        appointmentTime: timeStr,
        etaHours: etaHours,
        etaMinutes: etaMinutes,
        adminNotes: adminNotes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment imewekwa ✅'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Service Bookings',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in [
                  'ALL',
                  'PENDING_PAYMENT',
                  'DEPOSIT_PAID',
                  'CONFIRMED',
                  'COMPLETED',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: ChoiceChip(
                      label: Text(
                        s == 'ALL' ? 'Zote' : s.replaceAll('_', ' '),
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text('Hakuna booking',
                            style: GoogleFonts.poppins(
                                color: AppColors.textMuted)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final b = _filtered[i];
                            final status = b['status']?.toString() ?? '';
                            final canVerify =
                                status == 'PENDING_PAYMENT';
                            final canSetAppt = status == 'DEPOSIT_PAID' ||
                                status == 'CONFIRMED';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.handyman,
                                              color: _statusColor(status),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  b['service_name']
                                                          ?.toString() ??
                                                      'Service',
                                                  style:
                                                      GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700)),
                                              Text(
                                                  b['booking_number']
                                                          ?.toString() ??
                                                      '',
                                                  style:
                                                      GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: AppColors
                                                              .textMuted)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(status,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _row('Mteja',
                                        b['user_email']?.toString() ?? '-'),
                                    _row(
                                        'Gari',
                                        '${b['vehicle_make']} ${b['vehicle_model']}'),
                                    _row('Deposit',
                                        'TSh ${NumberFormat("#,##0").format(b['deposit_amount'] ?? 0)}'),
                                    _row('Total',
                                        'TSh ${NumberFormat("#,##0").format(b['total_price'] ?? 0)}'),
                                    if (b['appointment_date'] != null)
                                      _row('Appointment',
                                          '${b['appointment_date']} ${b['appointment_time'] ?? ''}'),
                                    const SizedBox(height: 8),
                                    if (canVerify)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _verifyPayment(b),
                                          icon: const Icon(Icons.verified,
                                              size: 18),
                                          label: Text('Thibitisha Malipo',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    if (canSetAppt)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _setAppointment(b),
                                          icon:
                                              const Icon(Icons.calendar_today,
                                                  size: 18),
                                          label: Text('Set Appointment',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
