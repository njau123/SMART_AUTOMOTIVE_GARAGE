import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminOBDScreen extends StatefulWidget {
  const AdminOBDScreen({super.key});
  @override
  State<AdminOBDScreen> createState() => _AdminOBDScreenState();
}

class _AdminOBDScreenState extends State<AdminOBDScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _payments = [];
  String _filter = 'PENDING';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminOBDAPI.list(status: _filter);
      final data = (res['data'] as List?) ?? [];
      if (!mounted) return;
      setState(() { _payments = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _verify(int id) async {
    try {
      final res = await AdminOBDAPI.verify(id);
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

  Future<void> _reject(int id) async {
    final ctrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kataa malipo?'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Sababu (si lazima)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kataa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await AdminOBDAPI.reject(id, reason: ctrl.text.trim());
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

  String _fmtTime(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, "0")}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'PENDING': case 'CREATED': return Colors.orange;
      case 'FAILED': return Colors.red;
      case 'EXPIRED': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Malipo ya OBD Scanner',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['PENDING', 'COMPLETED', 'FAILED', 'EXPIRED', '']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              f.isEmpty ? 'Zote' : f,
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            selected: _filter == f,
                            onSelected: (_) {
                              setState(() => _filter = f);
                              _load();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _payments.isEmpty
                        ? Center(
                            child: Text('Hakuna malipo',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _payments.length,
                              itemBuilder: (_, i) => _card(_payments[i] as Map),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map p) {
    final status = p['status']?.toString() ?? 'UNKNOWN';
    final color = _statusColor(status);
    final countdown = int.tryParse(p['countdown_seconds']?.toString() ?? '0') ?? 0;
    final isPending = ['PENDING', 'CREATED'].contains(status.toUpperCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p['reference']?.toString() ?? '-',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'TSh ${(double.tryParse(p['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Mtumiaji', p['user_name']?.toString() ?? p['user_email']?.toString() ?? '-'),
          _row('Email', p['user_email']?.toString() ?? '-'),
          _row('Namba', p['user_phone']?.toString() ?? '-'),
          _row('Mtandao', p['detected_network']?.toString() ?? '-'),
          if (isPending && countdown > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Muda uliobaki: ${_fmtTime(countdown)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(p['id'] as int),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('Kataa', style: GoogleFonts.poppins(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _verify(p['id'] as int),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('Thibitisha', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
