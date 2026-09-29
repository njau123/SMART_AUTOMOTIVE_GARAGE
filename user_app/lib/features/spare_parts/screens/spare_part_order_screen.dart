import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'order_tracking_screen.dart';

class SparePartOrderScreen extends StatefulWidget {
  final Map<String, dynamic> part;

  const SparePartOrderScreen({super.key, required this.part});

  @override
  State<SparePartOrderScreen> createState() => _SparePartOrderScreenState();
}

class _SparePartOrderScreenState extends State<SparePartOrderScreen> {
  final _phoneCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  bool _ordering = false;

  int? _orderId;
  String _orderNumber = '';
  Map<String, dynamic>? _paymentResult;
  int _countdown = 45 * 60;
  Timer? _timer;
  bool _paidConfirmed = false;
  String _paymentMethod = 'MOBILE_MONEY';
  String _selectedBank = 'NMB';

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

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _bankAccountCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
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

  String? _detectNetwork(String phone) {
    if (phone.length != 10) return null;
    final p = phone.substring(0, 3);
    if (['075', '076', '074'].contains(p)) return 'Vodacom';
    if (['071', '065', '067'].contains(p)) return 'Tigo/Yas';
    if (['078', '068', '069'].contains(p)) return 'Airtel';
    if (['062', '061'].contains(p)) return 'Halotel';
    return null;
  }

  String? _detectBank(String acc) {
    if (acc.length < 8) return null;
    if (acc.startsWith('2321') || acc.startsWith('2010')) return 'NMB';
    if (acc.startsWith('0150') || acc.startsWith('0152')) return 'CRDB';
    if (acc.startsWith('0110') || acc.startsWith('0111')) return 'NBC';
    if (acc.startsWith('0700')) return 'Equity';
    return null;
  }

  Future<void> _buy() async {
    if (_paymentMethod == 'MOBILE_MONEY' && _phoneCtrl.text.trim().isEmpty) {
      _snack("Weka namba yako ya simu", error: true);
      return;
    }
    if (_paymentMethod == 'BANK' && _bankAccountCtrl.text.trim().isEmpty) {
      _snack("Weka account number yako", error: true);
      return;
    }

    setState(() => _ordering = true);
    try {
      // 1. Unda Order
      final orderRes = await SparePartOrderAPI.create(
        sparePartId: widget.part['id'] as int,
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        contactPhone: _paymentMethod == 'BANK'
            ? _bankAccountCtrl.text.trim()
            : _phoneCtrl.text.trim(),
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

      // 2. Initiate payment (kama AI Scanner)
      final payRes = await SparePartOrderAPI.payOrderDeposit(
        orderId: orderId,
        phoneNumber: _paymentMethod == 'BANK'
            ? _bankAccountCtrl.text.trim()
            : _phoneCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        bankName: _paymentMethod == 'BANK' ? _selectedBank : '',
      );

      if (!mounted) return;

      if (payRes['success'] == true) {
        setState(() {
          _orderId = orderId;
          _orderNumber = orderNumber;
          _paymentResult = payRes;
          _countdown = 45 * 60;
        });
        _startTimer();
        // Auto-schedule navigation (kama user anafunga dialog) — AI Scanner style
        _autoNavigateToTracking(orderId, orderNumber);
      } else {
        _snack(payRes['message']?.toString() ?? "Imeshindikana malipo", error: true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  void _autoNavigateToTracking(int orderId, String orderNumber) {
    // Baada ya sekunde 3 — hifadhi order na ruhusu user kwenda tracking
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Badilisha button text kuwa "Tumia Tracking" badala ya auto-navigate
      setState(() {});
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 0) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
    });
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_paymentResult == null ? 'Order Spare Part' : 'Lipa Deposit',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _paymentResult == null ? _buildForm() : _buildPayment(),
    );
  }

  Widget _buildForm() {
    final name = widget.part['name']?.toString() ?? 'Spare Part';
    final image = widget.part['main_image']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (image != null && image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(image, width: 60, height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconBox()),
                  )
                else
                  _iconBox(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('TSh ${_price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quantity
          Row(
            children: [
              Text('Idadi:', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final q = int.tryParse(_quantityCtrl.text) ?? 1;
                  if (q > 1) setState(() => _quantityCtrl.text = '${q - 1}');
                },
              ),
              Text(_quantityCtrl.text, style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  final q = int.tryParse(_quantityCtrl.text) ?? 1;
                  if (q < 20) setState(() => _quantityCtrl.text = '${q + 1}');
                },
              ),
              const Spacer(),
              Text('Jumla: TSh ${_total.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),

          // Payment method
          Text('Njia ya Malipo',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _methodBtn('MOBILE_MONEY', 'Mobile Money', Icons.phone_android)),
              const SizedBox(width: 8),
              Expanded(child: _methodBtn('BANK', 'Bank', Icons.account_balance)),
            ],
          ),
          const SizedBox(height: 14),

          // Phone / Bank account
          if (_paymentMethod == 'MOBILE_MONEY') ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Namba yako ya simu',
                hintText: '06XXXXXXXX au 07XXXXXXXX',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                counterText: '',
              ),
            ),
            if (_phoneCtrl.text.length == 10) ...[
              Builder(builder: (_) {
                final net = _detectNetwork(_phoneCtrl.text);
                if (net == null) {
                  return Text('⚠️ Mtandao haujulikani',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.red));
                }
                return Row(children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Mtandao: $net',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.green.shade800)),
                ]);
              }),
            ],
          ] else ...[
            _bankDropdown(),
            const SizedBox(height: 10),
            TextField(
              controller: _bankAccountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Account Number yako',
                prefixIcon: const Icon(Icons.account_balance, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_bankAccountCtrl.text.length >= 8) ...[
              Builder(builder: (_) {
                final bank = _detectBank(_bankAccountCtrl.text);
                if (bank == null) {
                  return Text('⚠️ Account pattern haijulikani',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange));
                }
                return Row(children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Bank: $bank',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.green.shade800)),
                ]);
              }),
            ],
          ],
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _ordering ? null : _buy,
              icon: _ordering
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment),
              label: Text(_ordering ? 'Inatuma...' : 'Anzisha Malipo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.settings, color: AppColors.primary),
      );

  Widget _methodBtn(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _bankDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBank,
          isExpanded: true,
          items: const [
            'NMB', 'CRDB', 'NBC', 'Azania', 'Equity', 'Stanbic',
            'Exim (TIB)', 'TPB', 'AccessBank', 'Absa', 'Diamond Trust',
          ].map((b) => DropdownMenuItem(
                value: b,
                child: Text(b, style: GoogleFonts.poppins(fontSize: 13)),
              )).toList(),
          onChanged: (v) => setState(() => _selectedBank = v ?? 'NMB'),
        ),
      ),
    );
  }

  Widget _buildPayment() {
    final expired = _countdown <= 0;
    final res = _paymentResult!;
    final data = res['data'] as Map? ?? {};
    final isMobile = _paymentMethod == 'MOBILE_MONEY';
    final instructions = isMobile
        ? data['instructions_mobile']?.toString() ?? ''
        : data['instructions_bank']?.toString() ?? '';
    final ussdCode = data['ussd_code']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: expired
                  ? [Colors.red, Colors.red.shade700]
                  : [Colors.orange, Colors.deepOrange]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 32),
                const SizedBox(height: 6),
                Text(expired ? 'Muda umeisha' : 'Lipa kabla ya:',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                Text(_fmt(_countdown),
                    style: GoogleFonts.poppins(
                        fontSize: 34, fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
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
                Text('${widget.part['name']} — Malipo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('TSh ${_total.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text('Ref: $_orderNumber',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(instructions,
                style: GoogleFonts.poppins(fontSize: 12, height: 1.6)),
          ),
          if (isMobile && ussdCode.isNotEmpty) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('tel:${Uri.encodeComponent(ussdCode)}');
                try {
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                } catch (_) {}
              },
              icon: const Icon(Icons.dialpad, size: 18),
              label: Text('Fungua Dialer ($ussdCode)',
                  style: GoogleFonts.poppins(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!_paidConfirmed)
            ElevatedButton.icon(
              onPressed: expired ? null : () => setState(() => _paidConfirmed = true),
              icon: const Icon(Icons.check),
              label: Text('Nimelipa',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
            ),
          if (_paidConfirmed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 10),
                  Text('Inasubiri uthibitisho wa admin...',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            orderId: _orderId!,
                            orderNumber: _orderNumber,
                            sparePartName: widget.part['name']?.toString() ?? 'Bidhaa',
                          ),
                        ),
                      );
                    },
                    child: Text('Fuatilia Oda',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
