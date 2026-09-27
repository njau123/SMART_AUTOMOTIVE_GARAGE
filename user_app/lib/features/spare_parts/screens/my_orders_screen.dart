import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'order_tracking_screen.dart';

/// My Orders — inaonyesha orders zote za user na countdown.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

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
      final list = await SparePartOrderAPI.myOrders();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING_PAYMENT':
        return Colors.orange;
      case 'PAID':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.indigo;
      case 'OUT_FOR_DELIVERY':
        return Colors.deepOrange;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING_PAYMENT':
        return 'Inasubiri malipo';
      case 'PAID':
        return 'Imelipwa';
      case 'PROCESSING':
        return 'Inaandaliwa';
      case 'OUT_FOR_DELIVERY':
        return 'Njiani kwako';
      case 'DELIVERED':
        return 'Imefikishwa';
      case 'CANCELLED':
        return 'Imefutwa';
      default:
        return s;
    }
  }

  Future<void> _confirmDelete(dynamic order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa oda?'),
        content: Text('Una uhakika kufuta oda ${order['order_number']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await SparePartOrderAPI.delete(order['id'] as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oda imefutwa'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imeshindwa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Vipuri Zangu',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 50, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins()),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Jaribu Tena'),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Hauna oda bado',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final o = _orders[i];
                          final status = o['status']?.toString() ?? '';
                          final isDone = status == 'DELIVERED';
                          final canDelete = status == 'PENDING_PAYMENT' ||
                              status == 'CANCELLED';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderTrackingScreen(
                                      orderId: o['id'] as int,
                                      orderNumber:
                                          o['order_number']?.toString() ?? '',
                                      sparePartName:
                                          o['spare_part_name']?.toString() ??
                                              o['spare_part']?['name']
                                                  ?.toString() ??
                                              'Bidhaa',
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
                                            color: _statusColor(status)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isDone
                                                ? Icons.check_circle
                                                : Icons.local_shipping,
                                            color: _statusColor(status),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                o['spare_part_name']
                                                        ?.toString() ??
                                                    o['spare_part']?['name']
                                                        ?.toString() ??
                                                    'Bidhaa',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                o['order_number']?.toString() ??
                                                    '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'TSh ${NumberFormat("#,##0").format(o['total_price'] ?? 0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          o['created_at']
                                                  ?.toString()
                                                  .substring(0, 10) ??
                                              '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (canDelete) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _confirmDelete(o),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red, size: 18),
                                          label: Text(
                                            'Futa',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ],
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
