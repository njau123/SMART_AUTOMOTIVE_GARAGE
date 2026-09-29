import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import 'booking_detail_screen.dart';
import '../../obd/screens/obd_scanner_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Bookings
  List<dynamic> _bookings = [];
  bool _loadingBookings = true;
  String? _errorBookings;

  // OBD
  Map<String, dynamic>? _obdPayment;
  bool _loadingObd = true;
  Timer? _obdTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadBookings();
    _loadObd();
    notificationRefreshNotifier.addListener(_onFcmNotification);
    // Auto-refresh OBD kila 10s (kupata admin verify)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadObd(silent: true);
    });
  }

  @override
  void dispose() {
    notificationRefreshNotifier.removeListener(_onFcmNotification);
    _tabs.dispose();
    _obdTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ══════════════════ BOOKINGS ══════════════════

  Future<void> _loadBookings() async {
    setState(() {
      _loadingBookings = true;
      _errorBookings = null;
    });
    try {
      final data = await BookingAPI.myBookings();
      if (!mounted) return;
      setState(() {
        _bookings = data;
        _loadingBookings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBookings = e.toString().replaceAll('Exception: ', '');
        _loadingBookings = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'ARRIVING':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.indigo;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ══════════════════ OBD ══════════════════

  Future<void> _loadObd({bool silent = false}) async {
    if (!silent) setState(() => _loadingObd = true);
    try {
      final res = await OBDAPI.getOBDPaymentStatus();
      final data = res['data'] as Map?;
      if (!mounted) return;
      setState(() {
        _obdPayment = data != null ? Map<String, dynamic>.from(data) : null;
        _loadingObd = false;
      });
      _startObdTimerIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingObd = false;
      });
    }
  }

  void _onFcmNotification() {
    final type = notificationRefreshNotifier.value;
    if (type == 'obd_verified' || type == 'service_verified' || type == 'payment') {
      _loadObd(silent: true);
    }
  }

  void _startObdTimerIfNeeded() {
    _obdTimer?.cancel();
    if (_obdPayment == null) return;
    final status = (_obdPayment!['status'] ?? '').toString().toUpperCase();
    final isPending = ['PENDING', 'CREATED'].contains(status);
    if (!isPending) return;
    final remaining = int.tryParse(
            _obdPayment!['countdown_seconds']?.toString() ?? '0') ??
        0;
    if (remaining <= 0) return;

    _obdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _obdPayment == null) {
        t.cancel();
        return;
      }
      final current =
          int.tryParse(_obdPayment!['countdown_seconds']?.toString() ?? '0') ??
              0;
      if (current <= 0) {
        t.cancel();
        // Reload kutoka backend kupata status mpya
        _loadObd(silent: true);
        return;
      }
      setState(() {
        _obdPayment!['countdown_seconds'] = current - 1;
      });
    });
  }

  String _fmtCountdown(int secs) {
    if (secs < 0) secs = 0;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, "0")}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
  }

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ObdScannerScreen()),
    );
    _loadObd(silent: true);
  }

  Future<void> _startNewPayment() async {
    await _openScanner();
    _loadObd(silent: true);
  }

  // ══════════════════ BUILD ══════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookings Zangu'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Bookings', icon: Icon(Icons.event_note, size: 18)),
            Tab(text: 'OBD Scanner', icon: Icon(Icons.bluetooth_searching, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildBookingsTab(),
          _buildObdTab(),
        ],
      ),
    );
  }

  // ══════════════════ TAB 1 — BOOKINGS ══════════════════

  Widget _buildBookingsTab() {
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorBookings != null) return _buildErrorBookings();
    if (_bookings.isEmpty) return _buildEmptyBookings();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (_, i) => _card(_bookings[i]),
      ),
    );
  }

  Widget _buildErrorBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_errorBookings ?? 'Error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadBookings, child: const Text('Jaribu Tena')),
        ],
      ),
    );
  }

  Widget _buildEmptyBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Hakuna bookings bado',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Book huduma kutoka kwa mechanics',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _card(dynamic b) {
    final status = b['status']?.toString() ?? 'PENDING';
    final color = _statusColor(status);
    final mechanicName = b['mechanic_name']?.toString() ?? 'Inasubiri';
    final serviceName = b['service_name']?.toString() ?? 'Huduma';
    final scheduled = b['scheduled_date']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: b['id'] as int),
            ),
          );
          if (result == true) _loadBookings();
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.build_circle, color: color, size: 22),
        ),
        title: Text(b['booking_number']?.toString() ?? 'Booking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: GoogleFonts.poppins(fontSize: 12)),
            Text('Mechanic: $mechanicName',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            if (scheduled.isNotEmpty)
              Text('Tarehe: $scheduled',
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
    );
  }

  // ══════════════════ TAB 2 — OBD SCANNER ══════════════════

  Widget _buildObdTab() {
    if (_loadingObd) {
      return const Center(child: CircularProgressIndicator());
    }

    // Hakuna payment bado
    if (_obdPayment == null || _obdPayment!['has_payment'] != true) {
      return _buildObdEmpty();
    }

    final status = (_obdPayment!['status'] ?? '').toString().toUpperCase();
    final isPaid = _obdPayment!['is_paid'] == true;
    final isExpired = _obdPayment!['is_expired'] == true ||
        status == 'EXPIRED';
    final isFailed = status == 'FAILED';
    final isPending = ['PENDING', 'CREATED'].contains(status);
    final remaining = int.tryParse(
            _obdPayment!['countdown_seconds']?.toString() ?? '0') ??
        0;

    return RefreshIndicator(
      onRefresh: () => _loadObd(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ══════ PAID / VERIFIED ══════
          if (isPaid) ...[
            _statusBanner(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Umeshalipa — Tumia Scanner',
              subtitle:
                  'Admin amethibitisha malipo yako. Unaweza kutumia OBD-II scanner sasa.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text('Fungua OBD Scanner',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // ══════ PENDING / WAITING FOR ADMIN ══════
          if (isPending && !isExpired) ...[
            _statusBanner(
              icon: Icons.timer,
              color: Colors.orange,
              title: 'Inasubiri Uthibitisho',
              subtitle:
                  'Malipo yako yameanzishwa. Admin atathibitisha mara moja baada ya kuona muamala.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text('Muda uliobaki',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.orange.shade900)),
                  const SizedBox(height: 8),
                  Text(
                    _fmtCountdown(remaining),
                    style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TSh ${(_obdPayment!['amount'] as num?)?.toStringAsFixed(0) ?? "25,000"}',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (_obdPayment!['reference'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${_obdPayment!['reference']}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Umri wa maelekezo yako ya malipo yanatumika. Kama hujalipa, endelea na maelekezo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ],

          // ══════ EXPIRED / FAILED ══════
          if (isExpired || isFailed) ...[
            _statusBanner(
              icon: isFailed ? Icons.cancel : Icons.timer_off,
              color: Colors.red,
              title: isFailed ? 'Malipo Yamekataliwa' : 'Muda Umeisha',
              subtitle: isFailed
                  ? 'Malipo yako hayakuthibitishwa. Tafadhali jaribu tena.'
                  : 'Muda wa malipo umepita. Anzisha upya kutumia scanner.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startNewPayment,
                icon: const Icon(Icons.refresh),
                label: Text('Anzisha Malipo Tena',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObdEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching,
                size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Hakuna Malipo ya OBD',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Lipa TSh 25,000 kutumia OBD-II Scanner kuchunguza gari lako.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.play_arrow),
                label: Text('Anza OBD Scanner',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
