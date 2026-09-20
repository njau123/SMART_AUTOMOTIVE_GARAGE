import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> _requests = [];
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
      final data = await BookingMechanicAPI.pendingBookings();
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _accept(int bookingId) async {
    int hours = 1;
    int minutes = 0;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Kubali Kazi — Weka ETA"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weka mda utakaomfikia mteja:"),
              const SizedBox(height: 16),
              Text('Masaa: $hours'),
              Slider(
                value: hours.toDouble(),
                min: 1, max: 24, divisions: 23,
                label: '$hours',
                onChanged: (v) => setDialogState(() => hours = v.toInt()),
              ),
              Text('Dakika: $minutes'),
              Slider(
                value: minutes.toDouble(),
                min: 0, max: 59, divisions: 59,
                label: '$minutes',
                onChanged: (v) => setDialogState(() => minutes = v.toInt()),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Utamfikia mteja baada ya ${hours}h ${minutes}m',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ghairi"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, {'hours': hours, 'minutes': minutes}),
              child: const Text("Kubali"),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final res = await BookingMechanicAPI.acceptBooking(
        bookingId: bookingId,
        travelHours: result['hours']!,
        travelMinutes: result['minutes']!,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Umekubali! ETA: ${result['hours']}h ${result['minutes']}m"),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? "Imeshindikana"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pitisha Kazi?"),
        content: const Text("Kazi itarudi kwa admin ili ampangie fundi mwingine. Una uhakika?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hapana")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ndiyo, Pitisha"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await JobsAPI.rejectJob(bookingId);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Umepitisha kazi hii."), backgroundColor: Colors.orange),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests Zangu'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _requests.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(child: Text(_error ?? 'Error', style: GoogleFonts.poppins())),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu Tena'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text('Hakuna requests bado', style: GoogleFonts.poppins(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Wateja wakikuchagua, utaona hapa.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _card(_requests[i]),
    );
  }

  Widget _card(dynamic r) {
    final custName = r['customer_name']?.toString() ?? 'Mteja';
    final service = r['service_name']?.toString() ?? 'Service';
    final vehicle = r['vehicle_name']?.toString() ?? 'Gari';
    final total = r['total_price']?.toString() ?? '0';
    final deposit = r['deposit_amount']?.toString() ?? '0';
    final notes = r['customer_notes']?.toString() ?? '';
    final date = r['scheduled_date']?.toString() ?? '';
    final time = r['scheduled_time']?.toString() ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    custName.isNotEmpty ? custName[0].toUpperCase() : 'M',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(custName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text(service, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('MPYA',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(Icons.directions_car, vehicle),
            _row(Icons.calendar_today, '$date • $time'),
            _row(Icons.payments_outlined, 'Total: TSh $total • Deposit: TSh $deposit'),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('"$notes"', style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(r['id'] as int),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Pitisha"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _accept(r['id'] as int),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Kubali"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }
}
