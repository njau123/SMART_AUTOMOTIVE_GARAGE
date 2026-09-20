import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _countdown;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await BookingAPI.getDetail(widget.bookingId);
      if (!mounted) return;

      setState(() {
        _booking = booking;
        _loading = false;
      });

      // Anza countdown kama status inahitaji
      _startCountdownIfNeeded();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _startCountdownIfNeeded() {
    _timer?.cancel();

    final status = _booking?['status']?.toString().toUpperCase() ?? '';
    if (status == 'ACCEPTED' || status == 'ARRIVING' || status == 'IN_PROGRESS') {
      _refreshCountdown();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _refreshCountdown(),
      );
    }
  }

  Future<void> _refreshCountdown() async {
    try {
      final c = await BookingAPI.getCountdown(widget.bookingId);
      if (!mounted) return;
      setState(() => _countdown = c);

      // Kama countdown imeisha — refresh booking + stop timer
      if (c['is_expired'] == true) {
        _timer?.cancel();
      }
    } catch (_) {
      // Puuza — tutajaribu tena sekunde ijayo
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'ARRIVING': return Colors.purple;
      case 'IN_PROGRESS': return Colors.indigo;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED':
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAll,
            child: const Text('Jaribu Tena'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final b = _booking ?? {};
    final status = b['status']?.toString().toUpperCase() ?? 'PENDING';
    final statusColor = _statusColor(status);
    final statusLabel = status.replaceAll('_', ' ');

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== COUNTDOWN CARD (kama status ni ACCEPTED/ARRIVING) =====
          if (_countdown != null &&
              (status == 'ACCEPTED' || status == 'ARRIVING'))
            _buildCountdownCard(),

          // ===== STATUS CARD =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hali ya Booking',
                    style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(statusLabel,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(b['booking_number']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== SERVICE INFO =====
          _sectionTitle('Huduma'),
          _infoCard([
            _row(Icons.build_outlined, 'Huduma',
                b['service_name']?.toString() ?? '—'),
            _row(Icons.attach_money, 'Bei',
                'TSh ${b['total_price'] ?? b['service_price'] ?? '0'}'),
          ]),
          const SizedBox(height: 12),

          // ===== MECHANIC INFO =====
          _sectionTitle('Mechanic'),
          _infoCard([
            _row(Icons.person, 'Jina',
                b['mechanic_name']?.toString() ?? 'Inasubiri'),
            if ((b['mechanic_phone'] ?? '').toString().isNotEmpty)
              _row(Icons.phone, 'Simu', b['mechanic_phone']?.toString() ?? '—'),
          ]),
          const SizedBox(height: 12),

          // ===== VEHICLE INFO =====
          if (b['vehicle_details'] != null || b['vehicle'] != null)
            ...[
              _sectionTitle('Gari'),
              _infoCard([
                _row(Icons.directions_car, 'Gari',
                    b['vehicle_name']?.toString() ?? '—'),
              ]),
              const SizedBox(height: 12),
            ],

          // ===== TIME =====
          _sectionTitle('Muda'),
          _infoCard([
            _row(Icons.access_time, 'Imeundwa', _formatDateTime(b['created_at']?.toString())),
            if ((b['accepted_at'] ?? '').toString().isNotEmpty)
              _row(Icons.check_circle, 'Imekubaliwa',
                  _formatDateTime(b['accepted_at']?.toString())),
            if ((b['scheduled_date'] ?? '').toString().isNotEmpty)
              _row(Icons.calendar_today, 'Tarehe ya Kazi',
                  b['scheduled_date']?.toString() ?? '—'),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    final c = _countdown!;
    final seconds = (c['remaining_seconds'] ?? 0) as int;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final isExpired = c['is_expired'] == true;

    // Progress bar
    final totalSeconds = ((c['travel_hours'] ?? 1) as int) * 3600 +
        ((c['travel_minutes'] ?? 0) as int) * 60;
    final progress = totalSeconds > 0
        ? (1.0 - (seconds / totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.green, Colors.green.shade700]
              : [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isExpired ? Icons.check_circle : Icons.directions_car,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            isExpired
                ? 'Mechanic Anakuja Sasa!'
                : 'Mechanic Anakuja Baada Ya',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExpired
                ? 'Tafadhali msubiri mechanic afike'
                : 'Anakufikia hivi karibuni',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(t,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
