import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// Order tracking — inaonyesha countdown, ETA, na YES/NO confirmation.
class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String sparePartName;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.sparePartName,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _pollTimer;
  Timer? _localTick;
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _actioning = false;
  int _localSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    _localTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _localSeconds > 0) {
        setState(() => _localSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _localTick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await SparePartOrderAPI.getOrderStatus(widget.orderId);
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() {
        _status = data;
        _localSeconds = int.tryParse(
              data['delivery_countdown_seconds']?.toString() ?? '0',
            ) ??
            int.tryParse(
              data['payment_countdown_seconds']?.toString() ?? '0',
            ) ??
            0;
        _loading = false;
      });

      // Kama countdown imeisha na haijathibitishwa → onyesha dialog
      if (data['is_delivery_due'] == true && !_actioning) {
        _actioning = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showReceiptDialog();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _showDeliveryGpsDialog() async {
    final addrCtrl = TextEditingController();
    DateTime? pickupDate;
    TimeOfDay? pickupTime;
    double? lat, lng;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delivery Yako',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chagua siku + weka location yako',
                    style: GoogleFonts.poppins(fontSize: 12)),
                const SizedBox(height: 12),
                // Pickup date
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final p = await showDatePicker(
                      context: context,
                      initialDate: now.add(const Duration(days: 1)),
                      firstDate: now.add(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 30)),
                    );
                    if (p != null) setD(() => pickupDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        pickupDate != null
                            ? DateFormat('yyyy-MM-dd').format(pickupDate!)
                            : 'Chagua siku ya kupokea',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                // Pickup time
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (t != null) setD(() => pickupTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        pickupTime != null
                            ? '${pickupTime!.hour.toString().padLeft(2, '0')}:${pickupTime!.minute.toString().padLeft(2, '0')}'
                            : 'Chagua saa',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                // Address
                TextField(
                  controller: addrCtrl,
                  decoration: InputDecoration(
                    labelText: 'Address (mfano: Mbezi Mwisho)',
                    prefixIcon: const Icon(Icons.home_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                // GPS
                InkWell(
                  onTap: () async {
                    try {
                      LocationPermission perm = await Geolocator.checkPermission();
                      if (perm == LocationPermission.denied) {
                        perm = await Geolocator.requestPermission();
                      }
                      final pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 15),
                      );
                      setD(() { lat = pos.latitude; lng = pos.longitude; });
                    } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lat != null
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: lat != null ? Colors.green : Colors.orange),
                    ),
                    child: Row(children: [
                      Icon(lat != null ? Icons.check_circle : Icons.my_location,
                          color: lat != null ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        lat != null ? 'GPS: ${lat!.toStringAsFixed(5)}' : 'Washa GPS',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghairi')),
            ElevatedButton(
              onPressed: (lat == null || addrCtrl.text.trim().isEmpty || pickupDate == null)
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Hifadhi', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(pickupDate!);
      final timeStr = pickupTime != null
          ? '${pickupTime!.hour.toString().padLeft(2, '0')}:${pickupTime!.minute.toString().padLeft(2, '0')}'
          : '';
      await SparePartOrderAPI.setOrderDeliveryGps(
        orderId: widget.orderId,
        latitude: lat!,
        longitude: lng!,
        address: addrCtrl.text.trim(),
        pickupDate: dateStr,
        pickupTime: timeStr,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery imewekwa ✅'), backgroundColor: Colors.green),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showReceiptDialog() async {
    final answer = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Umepokea bidhaa?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Have you already received your spare part?',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'no'),
            child: Text('NO', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'yes'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('YES',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (answer == 'yes') {
      await _confirmReceipt('yes');
    } else if (answer == 'no') {
      await _showExtensionDialog();
    } else {
      _actioning = false;
    }
  }

  Future<void> _showExtensionDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sorry',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Sorry. Can you allow some extra time for our delivery in case of an emergency? (+15 min)',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Allow +15 min',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await SparePartOrderAPI.extendOrderTime(
          orderId: widget.orderId,
          minutes: 15,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dakika 15 zimeongezwa'),
            backgroundColor: Colors.green,
          ),
        );
        _actioning = false;
        await _load();
      } catch (e) {
        _actioning = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      _actioning = false;
    }
  }

  Future<void> _confirmReceipt(String answer) async {
    try {
      final res = await SparePartOrderAPI.confirmReceipt(
        orderId: widget.orderId,
        answer: answer,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asante kwa kutumia Smart Garage!'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
        _actioning = false;
      }
    } catch (e) {
      _actioning = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _status ?? {};
    final status = data['status']?.toString() ?? '';
    final isPayment = status == 'PENDING_PAYMENT';
    final isDelivery = ['PAID', 'PROCESSING', 'OUT_FOR_DELIVERY'].contains(status);
    final isDone = status == 'DELIVERED' || data['receipt_confirmed'] == true;
    final isExpired = data['is_payment_expired'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Oda ${widget.orderNumber}',
            style: GoogleFonts.poppins(fontSize: 15)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle
                        : (isDelivery ? Icons.local_shipping : Icons.shopping_bag),
                    size: 48,
                    color: isDone
                        ? Colors.green
                        : (isDelivery ? Colors.orange : AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.sparePartName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDone
                        ? 'Imekamilika'
                        : (isDelivery ? 'Njiani kwako' : 'Inasubiri malipo'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Countdown card
            if (!isDone && (isPayment || isDelivery))
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExpired
                        ? [Colors.red, Colors.red.shade700]
                        : (isDelivery
                            ? [Colors.orange, Colors.deepOrange]
                            : [AppColors.primary, AppColors.primaryDark]),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off : Icons.timer,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isExpired
                          ? 'Muda umeisha — Anzisha tena'
                          : (isDelivery
                              ? 'Delivery inafika baada ya:'
                              : 'Malipo yanaisha baada ya:'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(_localSeconds),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    if (isDelivery && data['distance_km'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Umbali: ${data['distance_km']} km',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Delivery details
            if (isDelivery || isDone) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Details',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _row(Icons.location_on, 'Eneo',
                        data['delivery_location']?.toString() ?? '-'),
                    _row(Icons.calendar_today, 'Tarehe',
                        data['delivery_date']?.toString() ?? '-'),
                    if (data['receipt_extended_count'] != 0)
                      _row(Icons.add_alarm, 'Extend',
                          '${data['receipt_extended_count']}x'),
                  ],
                ),
              ),
            ],

            // GPS + Pickup date button (kama haijawekwa)
            if ((status == 'PAID' || status == 'PROCESSING') &&
                data['delivery_location'] == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showDeliveryGpsDialog,
                    icon: const Icon(Icons.location_on),
                    label: Text('Weka Location + Siku ya Kupokea',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ),

            // Confirm button (kama countdown imeisha)
            if (isDelivery && data['is_delivery_due'] == true && !_actioning)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _showReceiptDialog,
                  icon: const Icon(Icons.check),
                  label: Text('Thibitisha Kupokea',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
