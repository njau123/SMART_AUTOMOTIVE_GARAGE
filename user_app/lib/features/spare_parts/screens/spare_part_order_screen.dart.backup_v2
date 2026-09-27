import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'order_delivery_screen.dart';

class SparePartOrderScreen extends StatefulWidget {
  final Map<String, dynamic> part;

  const SparePartOrderScreen({super.key, required this.part});

  @override
  State<SparePartOrderScreen> createState() => _SparePartOrderScreenState();
}

class _SparePartOrderScreenState extends State<SparePartOrderScreen> {
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  bool _ordering = false;

  double get _price =>
      double.tryParse((widget.part['price'] ?? widget.part['base_price'] ?? '0').toString()) ?? 0;

  double get _total {
    final qty = int.tryParse(_quantityCtrl.text) ?? 1;
    return _price * qty;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _quantityCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadUser() async {
    try {
      final profile = await AuthAPI.getProfile();
      if (!mounted) return;
      setState(() {
        _phoneCtrl.text = profile['phone_number']?.toString() ?? '';
      });
    } catch (_) {}
  }

  Future<void> _buy() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _snack("Weka namba yako ya simu", error: true); return;
    }

    setState(() => _ordering = true);
    try {
      // 1. Unda Order
      final orderRes = await SparePartOrderAPI.create(
        sparePartId: widget.part['id'] as int,
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        contactPhone: _phoneCtrl.text.trim(),
      );

      if (orderRes['success'] != true) {
        _snack(orderRes['message']?.toString() ?? "Imeshindikana kuunda oda", error: true);
        return;
      }

      final orderData = orderRes['data'] as Map? ?? {};
      final orderId = orderData['id'] as int?;
      final orderNumber = orderData['order_number']?.toString() ?? '';

      if (orderId == null) {
        _snack("Order ID haipo", error: true);
        return;
      }

      // 2. Anzisha Payment (unified)
      final payRes = await PaymentAPI.initiateUnified(
        amount: _total,
        purpose: 'SPARE_PART',
        methodType: 'MOBILE_MONEY',
        identifier: _phoneCtrl.text.trim(),
        description: 'Order: ${widget.part['name']} x${_quantityCtrl.text}',
        referenceId: orderId.toString(),
      );

      if (!mounted) return;

      if (payRes['success'] == true) {
        _showSuccessDialog(payRes, orderId, orderNumber);
      } else {
        _snack(payRes['message']?.toString() ?? "Imeshindikana malipo", error: true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  void _showSuccessDialog(
    Map<String, dynamic> res,
    int orderId,
    String orderNumber,
  ) {
    final instructions = res['instructions']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text("Oda Imepokelewa!",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (orderNumber.isNotEmpty)
                Text("Namba ya Oda: $orderNumber",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Maelekezo ya Malipo:",
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      instructions.isNotEmpty
                          ? instructions
                          : "Fuata maelekezo ya malipo.",
                      style: GoogleFonts.poppins(fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Baada ya kulipa, weka taarifa za delivery (wapi, lini, saa ngapi).",
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Elekeza kwenye OrderDeliveryScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDeliveryScreen(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    sparePartName: widget.part['name']?.toString() ?? 'Spare Part',
                  ),
                ),
              );
            },
            child: Text("Weka Delivery Info",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.part['name']?.toString() ?? 'Spare Part';
    final image = widget.part['main_image']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Order Spare Part")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    if (image != null && image.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(image, width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60, height: 60, color: AppColors.border,
                            child: const Icon(Icons.settings),
                          )),
                      )
                    else
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.settings, color: AppColors.primary),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          Text('TSh ${_price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text("Idadi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text("Namba yako ya simu", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "+255712345678",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              Text("Anwani ya kupelekewa", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "Mkoa, wilaya, mtaa, landmark",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Text("Maelezo ya ziada (optional)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("JUMLA:",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("TSh ${_total.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _ordering ? null : _buy,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(_ordering ? "Inatuma..." : "Buy Sasa"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
