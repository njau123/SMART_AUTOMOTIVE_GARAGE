import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class OrderDeliveryScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String sparePartName;

  const OrderDeliveryScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.sparePartName,
  });

  @override
  State<OrderDeliveryScreen> createState() => _OrderDeliveryScreenState();
}

class _OrderDeliveryScreenState extends State<OrderDeliveryScreen> {
  String _deliveryType = 'DELIVERY';
  final _locationCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _deliveryDate;
  bool _saving = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _regionCtrl.dispose();
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _timeCtrl.text = formatted);
    }
  }

  Future<void> _save() async {
    if (_deliveryType == 'DELIVERY') {
      if (_locationCtrl.text.trim().isEmpty) {
        _snack('Weka eneo la delivery', error: true);
        return;
      }
      if (_deliveryDate == null) {
        _snack('Chagua tarehe ya delivery', error: true);
        return;
      }
      if (_timeCtrl.text.trim().isEmpty) {
        _snack('Chagua mda wa delivery', error: true);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final res = await SparePartOrderAPI.updateDelivery(
        orderId: widget.orderId,
        deliveryType: _deliveryType,
        deliveryLocation: _locationCtrl.text.trim(),
        deliveryRegion: _regionCtrl.text.trim(),
        deliveryDate: _deliveryDate != null
            ? DateFormat('yyyy-MM-dd').format(_deliveryDate!)
            : null,
        deliveryTime: _timeCtrl.text.trim(),
        deliveryNotes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        _snack('Taarifa zimehifadhiwa! Admin atawasiliana nawe.');
        Navigator.pop(context, true);
      } else {
        _snack(res['message']?.toString() ?? 'Imeshindikana', error: true);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Delivery Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oda: ${widget.orderNumber}',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(widget.sparePartName,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Unataka kuchukua au kupelekwa?',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _typeCard(
                      title: 'Nikuletewe',
                      subtitle: 'Delivery',
                      icon: Icons.delivery_dining,
                      selected: _deliveryType == 'DELIVERY',
                      onTap: () => setState(() => _deliveryType = 'DELIVERY'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard(
                      title: 'Nitachukua',
                      subtitle: 'Pickup',
                      icon: Icons.storefront,
                      selected: _deliveryType == 'PICKUP',
                      onTap: () => setState(() => _deliveryType = 'PICKUP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_deliveryType == 'DELIVERY') ...[
                Text('Eneo la Delivery',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Mfano: Mbezi Mwisho, Kwa Mwenyekiti',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _regionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Mkoa (mfano: Dar es Salaam)',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Text('Tarehe ya Delivery',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _deliveryDate != null
                          ? DateFormat('EEEE, dd MMM yyyy')
                              .format(_deliveryDate!)
                          : 'Chagua tarehe',
                      style: GoogleFonts.poppins(
                        color: _deliveryDate != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text('Mda wa Delivery',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _timeCtrl.text.isNotEmpty
                          ? 'Saa ${_timeCtrl.text}'
                          : 'Chagua mda',
                      style: GoogleFonts.poppins(
                        color: _timeCtrl.text.isNotEmpty
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Pickup Location',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart Automotive Garage\nMbezi Mwisho, Dar es Salaam\n\n'
                        'Utapata notification oda yako ikiwa tayari.',
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Maelezo ya ziada (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text('Hifadhi Taarifa',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: selected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 6),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : Colors.black87)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
