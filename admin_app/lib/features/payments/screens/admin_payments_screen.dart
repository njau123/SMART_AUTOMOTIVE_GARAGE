import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String _filter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminPaymentAPI.list(
        status: _filter == 'ALL' ? null : _filter,
      );
      if (mounted) setState(() { _payments = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(dynamic p, {bool reject = false}) async {
    try {
      final res = await AdminPaymentAPI.verify(
        p['id'] as int,
        action: reject ? 'reject' : 'verify',
      );
      if (mounted && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reject ? "Malipo yamekataliwa" : "Malipo yamethibitishwa"),
            backgroundColor: reject ? Colors.red : Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showDetails(dynamic p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p['reference']?.toString() ?? '—',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Kiasi', 'TSh ${p['amount']}'),
            _detailRow('Hali', p['status']?.toString() ?? '—'),
            _detailRow('Aina', p['purpose']?.toString() ?? '—'),
            _detailRow('Njia', p['method']?.toString() ?? '—'),
            _detailRow('Provider', p['provider']?.toString() ?? '—'),
            _detailRow('Namba', p['phone_number']?.toString() ?? '—'),
            _detailRow('User', p['user_email']?.toString() ?? '—'),
            _detailRow('Tarehe', _fmtDate(p['created_at'])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) { return iso; }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('PENDING'),
                _chip('SUCCESS'),
                _chip('FAILED'),
                _chip('ALL'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? Center(child: Text("Hakuna malipo",
                        style: GoogleFonts.poppins()))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _payments.length,
                          itemBuilder: (_, i) => _card(_payments[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = label);
          _load();
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
    final status = (p['status'] ?? "").toString();
    final color = status == "SUCCESS" ? Colors.green
        : status == "FAILED" ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(p["reference"]?.toString() ?? "—",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: GoogleFonts.poppins(
                          fontSize: 10, color: color,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("TSh ${p["amount"]}",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("User: ${p["user_email"] ?? "—"}",
                  style: GoogleFonts.poppins(fontSize: 12)),
              Text("Simu: ${p["phone_number"] ?? "—"}",
                  style: GoogleFonts.poppins(fontSize: 12)),
              Text("Aina: ${p["purpose"] ?? "—"}",
                  style: GoogleFonts.poppins(fontSize: 12)),
              Text("Tarehe: ${_fmtDate(p['created_at'])}",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),

              if (status == "PENDING") ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Thibitisha"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _verify(p),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Kataa"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => _verify(p, reject: true),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
