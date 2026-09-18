import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/services/api_service.dart';
import 'spare_part_order_screen.dart';

class SparePartsScreen extends StatefulWidget {
  const SparePartsScreen({super.key});

  @override
  State<SparePartsScreen> createState() => _SparePartsScreenState();
}

class _SparePartsScreenState extends State<SparePartsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _parts = [];
  String _search = '';

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
      final data = await PublicAPI.getSpareParts();
      if (!mounted) return;
      setState(() {
        _parts = data;
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

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _parts;
    return _parts.where((p) {
      final n = (p['name'] ?? '').toString().toLowerCase();
      return n.contains(_search.toLowerCase());
    }).toList();
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
        title: Text(
          'Spare Parts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.sparePartsBg),
            fit: BoxFit.cover,
            opacity: 0.45,
          ),
        ),
        child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search spare parts...',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _buildGrid(),
            ),
          ),
        ],
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
                    style:
                        GoogleFonts.poppins(color: AppColors.textSecondary)),
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

  Widget _buildGrid() {
    final parts = _filtered;
    if (parts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _search.isEmpty ? 'No spare parts yet' : 'No results',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: parts.length,
      itemBuilder: (_, i) => _partTile(parts[i] as Map<String, dynamic>),
    );
  }

  Widget _partTile(Map<String, dynamic> part) {
    final name = (part['name'] ?? '').toString();
    final price = part['price'];
    final image = part['main_image']?.toString();
    final stock = part['stock_quantity'] ?? 0;
    final isAvailable = stock is int ? stock > 0 : true;

    return GestureDetector(
      onTap: () => _showDetails(part),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceAlt,
                  child: image != null && image.isNotEmpty
                      ? Image.network(
                          image.startsWith('http')
                              ? image
                              : 'http://10.0.2.2:8000$image',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.settings_outlined,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                        )
                      : const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textMuted,
                          size: 40,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (price != null)
                        Text(
                          'TSh ${_fmt(price)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Out of stock',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isAvailable
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> part) {
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
              (part['name'] ?? '').toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (part['description'] ?? 'No description').toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (part['price'] != null)
              _row('Price', 'TSh ${_fmt(part['price'])}'),
            if (part['part_number'] != null)
              _row('Part No.', part['part_number'].toString()),
            if (part['condition'] != null)
              _row('Condition', part['condition'].toString()),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SparePartOrderScreen(part: part),
                          ),
                        );
                        if (result == true && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order yako imepokelewa. Admin atathibitisha.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Buy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
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
