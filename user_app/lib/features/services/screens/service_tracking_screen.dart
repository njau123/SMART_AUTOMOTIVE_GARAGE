import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// Tracking ya service booking — countdown + ETA + YES/NO + extend.
class ServiceTrackingScreen extends StatefulWidget {
  final int bookingId;
  final String bookingNumber;
  final String serviceName;

  const ServiceTrackingScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    required this.serviceName,
  });

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  Timer? _poll;
  Timer? _tick;
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _actioning = false;
  int _localSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _localSeconds > 0) setState(() => _localSeconds--);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ServiceBookingAPI.getStatus(widget.bookingId);
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      setState(() {
        _status = data;
        _localSeconds = (data['eta_countdown_seconds'] as int?) ??
            (data['payment_countdown_seconds'] as int?) ??
            0;
        _loading = false;
      });
      if (data['is_eta_due'] == true && !_actioning) {
        _actioning = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showReceiptDialog();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReceiptDialog() async {
    final ans = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Umepata service?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Have you already received the service?',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'no'),
            child: Text('NO', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'yes'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('YES', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ans == 'yes') {
      await _confirmReceipt('yes');
    } else if (ans == 'no') {
      await _showExtendDialog();
    } else {
      _actioning = false;
    }
  }

  Future<void> _showExtendDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sorry', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Sorry. Can you allow some extra time for our mechanic in case of an emergency? (+15 min)',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
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
        await ServiceBookingAPI.extendTime(bookingId: widget.bookingId, minutes: 15);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dakika 15 zimeongezwa'),
              backgroundColor: Colors.green),
        );
        _actioning = false;
        await _load();
      } catch (e) {
        _actioning = false;
      }
    } else {
      _actioning = false;
    }
  }

  Future<void> _confirmReceipt(String answer) async {
    try {
      await ServiceBookingAPI.confirmReceipt(
        bookingId: widget.bookingId,
        answer: answer,
      );
      if (!mounted) return;
      if (answer == 'yes') await _showFeedbackDialog();
      await _load();
      _actioning = false;
    } catch (_) {
      _actioning = false;
    }
  }

  Future<void> _showFeedbackDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text('Thank you!', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Please give us your suggestion or feedback about the service you received.',
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Andika maoni...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Skip', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final txt = ctrl.text.trim();
              Navigator.pop(ctx);
              if (txt.isNotEmpty) {
                try {
                  await ServiceBookingAPI.sendFeedback(
                    bookingId: widget.bookingId,
                    feedback: txt,
                  );
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Tuma', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final d = _status ?? {};
    final status = d['status']?.toString() ?? '';
    final isPayment = status == 'PENDING_PAYMENT';
    final isConfirmed = status == 'CONFIRMED' || status == 'DEPOSIT_PAID' || status == 'IN_PROGRESS';
    final isDone = status == 'COMPLETED' || d['receipt_confirmed'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking ${widget.bookingNumber}',
            style: GoogleFonts.poppins(fontSize: 14)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  isDone ? Icons.check_circle
                      : (isConfirmed ? Icons.handyman : Icons.schedule),
                  size: 48,
                  color: isDone ? Colors.green : AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(widget.serviceName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  isDone ? 'Imekamilika'
                      : isConfirmed ? 'Inafanyika'
                          : 'Inasubiri malipo',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (!isDone && (isPayment || isConfirmed))
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isConfirmed
                    ? [Colors.orange, Colors.deepOrange]
                    : [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    isConfirmed
                        ? 'Mechanic anafika baada ya:'
                        : 'Malipo yanaisha baada ya:',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  Text(_fmt(_localSeconds),
                      style: GoogleFonts.poppins(
                          fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

          if (d['appointment_date'] != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointment',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Tarehe: ${d['appointment_date']}',
                      style: GoogleFonts.poppins(fontSize: 13)),
                  Text('Muda: ${d['appointment_time'] ?? '-'}',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
          ],

          if (isConfirmed && d['is_eta_due'] == true && !_actioning)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton.icon(
                onPressed: _showReceiptDialog,
                icon: const Icon(Icons.check),
                label: Text('Thibitisha Service',
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
    );
  }
}
