import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _services = [];

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
      final data = await PublicAPI.getServices();
      if (!mounted) return;
      setState(() {
        _services = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Our Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.servicesBg),
            fit: BoxFit.cover,
            opacity: 0.45,
          ),
        ),
        child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildList(),
      )),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(_error ?? 'Error',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_services.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text('No services yet',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = _services[i] as Map<String, dynamic>;
        return ServiceCard(
          service: s,
          onTap: () => _showDetails(s),
        );
      },
    );
  }

  void _showDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              (service['name'] ?? '').toString(),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (service['description'] ?? 'No description').toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (service['base_price'] != null)
              _row('Price', 'TSh ${_fmt(service['base_price'])}'),
            if (service['category_name'] != null && (service['category_name'] as String).isNotEmpty)
              _row('Category', service['category_name'].toString()),
            if (service['available_days'] is List && (service['available_days'] as List).isNotEmpty)
              _row('Siku', _fmtDays(service['available_days'])),
            if (service['start_time'] != null && service['end_time'] != null)
              _row('Muda', '${_fmtTime(service['start_time'])} - ${_fmtTime(service['end_time'])}'),
            if (service['estimated_duration_minutes'] != null)
              _row('Inachukua', 'Dakika ${service['estimated_duration_minutes']}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Huduma hii inapatikana. Karibu Automotive Smart Garage '
                        'kwa huduma kamili. Wasiliana nasi kwa maelezo zaidi.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Book this service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 14,
              )),
          Text(value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  String _fmtDays(dynamic days) {
    if (days is! List || days.isEmpty) return '';
    const map = {
      'MON': 'Jumatatu', 'TUE': 'Jumanne', 'WED': 'Jumatano',
      'THU': 'Alhamisi', 'FRI': 'Ijumaa', 'SAT': 'Jumamosi', 'SUN': 'Jumapili',
    };
    return days.map((d) => map[d.toString()] ?? d.toString()).join(', ');
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '';
    final s = t.toString();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  String _fmt(dynamic v) {
    try {
      return double.parse(v.toString())
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    } catch (_) {
      return v.toString();
    }
  }
}
