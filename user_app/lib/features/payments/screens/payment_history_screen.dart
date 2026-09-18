import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'payment_receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> _payments = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await PaymentAPI.getMyPayments();
      if (mounted) {
        setState(() {
          _payments = data;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_filter == 'ALL') {
      _filtered = _payments;
    } else {
      _filtered = _payments.where((p) {
        return (p['status']?.toString().toUpperCase() ?? '') == _filter;
      }).toList();
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _purposeIcon(String p) {
    switch (p.toUpperCase()) {
      case 'BOOKING':
        return Icons.event_available;
      case 'SPARE_PART':
        return Icons.settings;
      case 'SERVICE':
      case 'OBD_DIAGNOSIS':
        return Icons.psychology;
      case 'WALLET_TOPUP':
        return Icons.add_circle;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historia ya Malipo'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('ALL', 'Zote'),
                _chip('PENDING', 'Zinasubiri'),
                _chip('SUCCESS', 'Zilizofanikiwa'),
                _chip('FAILED', 'Zilizoshindwa'),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Hakuna malipo',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
            _applyFilter();
          });
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card(dynamic p) {
    final status = p['status']?.toString() ?? 'PENDING';
    final color = _statusColor(status);
    final amount = p['amount']?.toString() ?? '0';
    final purpose = p['purpose']?.toString() ?? 'PAYMENT';
    final reference = p['reference']?.toString() ?? '';
    final date = p['created_at']?.toString() ?? '';

    String formattedDate = date;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm')
          .format(DateTime.parse(date).toLocal());
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceiptScreen(payment: p),
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_purposeIcon(purpose), color: color, size: 22),
        ),
        title: Text(
          'TSh ${double.tryParse(amount)?.toStringAsFixed(0) ?? amount}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(purpose, style: GoogleFonts.poppins(fontSize: 12)),
            Text('Ref: $reference',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            Text(formattedDate,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
