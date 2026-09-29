import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  Timer? _refreshTimer;
  int _tick = 0;

  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  final _statuses = [
    'ALL',
    'PENDING_PAYMENT',
    'PAID',
    'PROCESSING',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminOrderAPI.list(status: _filter);
      if (mounted) setState(() { _orders = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyPayment(dynamic order) async {
    try {
      final res = await AdminOrderAPI.verify(order['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']?.toString() ?? 'Imethibitishwa'),
        backgroundColor: Colors.green,
      ));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _rejectPayment(dynamic order) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kataa malipo?'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Sababu', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Kataa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await AdminOrderAPI.reject(order['id'] as int, reason: ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']?.toString() ?? 'Imekataliwa'),
        backgroundColor: Colors.orange,
      ));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _fmtCountdown(int seconds) {
    if (seconds <= 0) return 'Imeisha';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PAID': case 'DELIVERED': case 'COMPLETED': return Colors.green;
      case 'PENDING_PAYMENT': return Colors.orange;
      case 'PROCESSING': case 'OUT_FOR_DELIVERY': return Colors.blue;
      case 'CANCELLED': case 'FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(dynamic order, String newStatus) async {
    try {
      final res = await AdminOrderAPI.updateStatus(
        orderId: order['id'] as int,
        status: newStatus,
      );
      if (mounted && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status → $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Oda: ${order['order_number']}',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(order['spare_part_name']?.toString() ?? '',
                  style: GoogleFonts.poppins(fontSize: 14)),
              const SizedBox(height: 16),

              _row(Icons.person, 'Mteja',
                  order['user_full_name']?.toString() ?? '—'),
              _row(Icons.email, 'Email',
                  order['user_email']?.toString() ?? '—'),
              _row(Icons.phone, 'Simu',
                  order['contact_phone']?.toString() ?? '—'),
              _row(Icons.numbers, 'Kiasi',
                  'x${order['quantity']} — TSh ${order['total_price']}'),
              _row(Icons.local_shipping, 'Aina',
                  order['delivery_type']?.toString() ?? '—'),

              if ((order['delivery_location'] ?? '').toString().isNotEmpty)
                _row(Icons.location_on, 'Eneo',
                    '${order['delivery_location']}, ${order['delivery_region'] ?? ''}'),

              if ((order['delivery_date'] ?? '').toString().isNotEmpty)
                _row(Icons.calendar_today, 'Tarehe',
                    order['delivery_date']?.toString() ?? '—'),

              if ((order['delivery_time'] ?? '').toString().isNotEmpty)
                _row(Icons.access_time, 'Mda',
                    order['delivery_time']?.toString() ?? '—'),

              if ((order['delivery_notes'] ?? '').toString().isNotEmpty)
                _row(Icons.notes, 'Maelezo',
                    order['delivery_notes']?.toString() ?? '—'),

              const SizedBox(height: 20),
              Text('Badilisha Status:',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(order, 'PAID', 'Imelipwa', Colors.blue),
                  _statusChip(order, 'PROCESSING', 'Inaandaliwa', Colors.orange),
                  _statusChip(order, 'OUT_FOR_DELIVERY', 'Njiani', Colors.purple),
                  _statusChip(order, 'DELIVERED', 'Imefikishwa', Colors.green),
                  _statusChip(order, 'CANCELLED', 'Imefutwa', Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Funga'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(dynamic order, String status, String label, Color color) {
    final current = order['status']?.toString() ?? '';
    final isCurrent = current == status;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrent ? color : color.withValues(alpha: 0.15),
        foregroundColor: isCurrent ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: isCurrent ? null : () {
        Navigator.pop(context);
        _updateStatus(order, status);
      },
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) { setState(() => _filter = v); _load(); },
            itemBuilder: (_) => _statuses
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _orders.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _card(_orders[i]),
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
          const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Hakuna oda bado',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _card(dynamic order) {
    final status = order['status']?.toString() ?? 'PENDING_PAYMENT';
    final color = _statusColor(status);
    final isPending = status == 'PENDING_PAYMENT';
    final countdown = int.tryParse(order['countdown_seconds']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () => _showDetails(order),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.shopping_bag, color: color, size: 22),
            ),
            title: Text(order['order_number']?.toString() ?? '—',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['spare_part_name']?.toString() ?? '',
                    style: GoogleFonts.poppins(fontSize: 12)),
                Text('${order['user_full_name'] ?? ''} • TSh ${order['total_price'] ?? 0}',
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
          if (isPending && countdown > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Countdown: ${_fmtCountdown(countdown)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectPayment(order),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text('Kataa',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyPayment(order),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text('Thibitisha',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
