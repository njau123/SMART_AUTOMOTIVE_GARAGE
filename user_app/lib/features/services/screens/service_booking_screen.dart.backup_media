import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'service_tracking_screen.dart';

/// Service Booking Screen — form ya gari + payment ya deposit 50%.
class ServiceBookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceBookingScreen({super.key, required this.service});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _creating = false;
  late bool _customMode;
  final _customServiceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _gpsFetching = false;
  double? _lat;
  double? _lng;
  int? _bookingId;
  String _bookingNumber = '';
  Map<String, dynamic>? _paymentResult;
  int _countdown = 45 * 60;
  Timer? _timer;
  bool _paidConfirmed = false;
  String _paymentMethod = 'MOBILE_MONEY';
  String _selectedBank = 'NMB';
  final _bankAccountCtrl = TextEditingController();
  String? _detectedBank;

  @override
  void initState() {
    super.initState();
    _customMode = widget.service == null;
    _loadProfile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _regCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    _customServiceCtrl.dispose();
    _addressCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await AuthAPI.getProfile();
      _phoneCtrl.text = p['phone_number']?.toString() ?? '';
      final v = p['vehicle'];
      if (v is Map) {
        _makeCtrl.text = v['make']?.toString() ?? '';
        _modelCtrl.text = v['model']?.toString() ?? '';
        _yearCtrl.text = v['year']?.toString() ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  double get _totalPrice =>
      double.tryParse(widget.service['base_price']?.toString() ?? '0') ?? 0;
  double get _deposit => _totalPrice * 0.5;


  Future<void> _fetchGps() async {
    if (_gpsFetching) return;

    // Kwanza funga keyboard kama ipo wazi
    FocusScope.of(context).unfocus();
    // Subiri kidogo (keyboard ifunge)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _gpsFetching = true);

    try {
      // 1. Check location services zimеwashwa
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _gpsFetching = false);
        _showGpsHelpDialog(
          'GPS Haijawashwa',
          'Tafadhali washa GPS/Location kwenye simu yako, kisha jaribu tena.',
          showSettings: true,
        );
        return;
      }

      // 2. Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _gpsFetching = false);
        _showGpsHelpDialog(
          'Ruhusa Imekataliwa',
          'Location permission imekataliwa. Tafadhali ruhusu kwenye settings.',
          showSettings: true,
        );
        return;
      }

      if (perm == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _gpsFetching = false);
        _showGpsHelpDialog(
          'Ruhusa Haijatolewa',
          'Chrome ilikataa ruhusa. Fungua Chrome → Site settings → Location → Allow, kisha jaribu tena.\n\n'
          'AU — Fungua app kwenye Chrome (sio PWA/installed app).',
          showSettings: false,
        );
        return;
      }

      // 3. Pata location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Location imepatikana'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showGpsHelpDialog(
        'GPS Imeshindwa',
        'Hitilafu: ${e.toString().replaceAll("Exception: ", "")}\n\n'
        '1. Hakikisha umeifungua kwenye Chrome (sio PWA)\n'
        '2. Hakikisha GPS imewashwa kwenye simu\n'
        '3. Ruhusu Location kwenye Chrome settings',
        showSettings: false,
      );
    } finally {
      if (mounted) setState(() => _gpsFetching = false);
    }
  }

  void _showGpsHelpDialog(String title, String message, {bool showSettings = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.location_off, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15))),
        ]),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
        actions: [
          if (showSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: Text('Fungua Settings', style: GoogleFonts.poppins()),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Sawa', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
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

  String? _detectBankFromAccount(String acc) {
    if (acc.length < 8) return null;
    // NMB patterns
    if (acc.startsWith('2321') || acc.startsWith('2010')) return 'NMB';
    if (acc.startsWith('0150') || acc.startsWith('0152')) return 'CRDB';
    if (acc.startsWith('0110') || acc.startsWith('0111')) return 'NBC';
    if (acc.startsWith('0700')) return 'Equity';
    return null;
  }

  Future<void> _createAndPay() async {
    if (!_formKey.currentState!.validate()) return;

    // GPS mandatory
    if (_lat == null || _lng == null) {
      _snack('Tafadhali washa GPS kupata location yako', error: true);
      return;
    }

    if (_addressCtrl.text.trim().isEmpty) {
      _snack('Weka address yako', error: true);
      return;
    }

    if (_customMode && _customServiceCtrl.text.trim().isEmpty) {
      _snack('Weka jina la service unayotaka', error: true);
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty && _paymentMethod == 'MOBILE_MONEY') {
      _snack('Weka namba yako ya simu', error: true);
      return;
    }

    setState(() => _creating = true);
    try {
      final res = await ServiceBookingAPI.createBooking(
        serviceId: _customMode ? null : widget.service?['id'] as int?,
        customServiceName: _customMode ? _customServiceCtrl.text.trim() : '',
        vehicleMake: _makeCtrl.text.trim(),
        vehicleModel: _modelCtrl.text.trim(),
        vehicleYear: _yearCtrl.text.trim(),
        vehicleRegistration: _regCtrl.text.trim(),
        vehicleNotes: _notesCtrl.text.trim(),
        serviceAddress: _addressCtrl.text.trim(),
        serviceLatitude: _lat,
        serviceLongitude: _lng,
      );

      if (res['success'] != true) {
        throw Exception(res['message']?.toString() ?? 'Imeshindikana');
      }

      final data = res['data'] as Map;
      final bookingId = data['id'] as int;
      final bookingNumber = data['booking_number']?.toString() ?? '';

      setState(() {
        _bookingId = bookingId;
        _bookingNumber = bookingNumber;
      });

      // Kama custom — subiri admin approve (haendi kwenye payment bado)
      if (_customMode) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ombi limetumwa. Admin atathibitisha bei.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Standard service — nenda payment
      final payRes = await ServiceBookingAPI.payDeposit(
        bookingId: bookingId,
        phoneNumber: _paymentMethod == 'BANK'
            ? _bankAccountCtrl.text.trim()
            : _phoneCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        bankName: _paymentMethod == 'BANK' ? _selectedBank : '',
      );

      if (payRes['success'] == true) {
        setState(() {
          _paymentResult = payRes;
          _countdown = 45 * 60;
        });
        _startTimer();
      } else {
        _snack(payRes['message']?.toString() ?? 'Malipo yameshindwa', error: true);
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.service['name']?.toString() ?? 'Service';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Weka Service',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _paymentResult == null
          ? _buildForm(serviceName)
          : _buildPayment(serviceName),
    );
  }

  Widget _buildForm(String serviceName) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceName,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('TSh ${_totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('50% = TSh ${_deposit.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_customMode) ...[
            Text('Service Unayotaka',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customServiceCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Mfano: Wheel Alignment, Engine Tune-up',
                prefixIcon: const Icon(Icons.build_circle_outlined, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Inahitajika'
                  : null,
            ),
            const SizedBox(height: 20),
          ],

          Text('Taarifa za Gari',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _field('Make (mfano Toyota)', _makeCtrl, Icons.directions_car,
              required: true),
          const SizedBox(height: 10),
          _field('Model (mfano Corolla)', _modelCtrl, Icons.directions_car,
              required: true),
          const SizedBox(height: 10),
          _field('Mwaka', _yearCtrl, Icons.calendar_today),
          const SizedBox(height: 10),
          _field('Registration', _regCtrl, Icons.confirmation_number),
          const SizedBox(height: 10),
          _field('Maelezo ya ziada', _notesCtrl, Icons.notes, maxLines: 3),
          const SizedBox(height: 20),
          Text('Location (Lazima)',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Weka address + washa GPS',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressCtrl,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Address (mfano: Mbezi Mwisho, Dar)',
              prefixIcon: const Icon(Icons.home_outlined, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Inahitajika'
                : null,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _fetchGps,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lat != null
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _lat != null ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lat != null ? Icons.check_circle : Icons.my_location,
                    color: _lat != null ? Colors.green : Colors.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gpsFetching
                          ? 'Inatafuta location...'
                          : _lat != null
                              ? 'GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                              : 'Washa GPS — Lazima kuendelea',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _lat != null
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  if (_gpsFetching)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Malipo — Deposit 50%',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _methodBtn('MOBILE_MONEY', 'Mobile Money', Icons.phone_android)),
              const SizedBox(width: 8),
              Expanded(child: _methodBtn('BANK', 'Bank', Icons.account_balance)),
            ],
          ),
          const SizedBox(height: 12),
          if (_paymentMethod == 'MOBILE_MONEY') ...[
            _field('Namba ya simu', _phoneCtrl, Icons.phone,
                keyboard: TextInputType.phone, required: true),
            const SizedBox(height: 6),
            if (_phoneCtrl.text.length == 10) ...[
              Builder(builder: (_) {
                final net = _detectNetwork(_phoneCtrl.text);
                if (net == null) {
                  return Text('⚠️ Mtandao haujulikani',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.red));
                }
                return Row(children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Mtandao: $net',
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: Colors.green.shade800)),
                ]);
              }),
            ],
          ],
          if (_paymentMethod == 'BANK') ...[
            _bankDropdown(),
            const SizedBox(height: 10),
            _field('Account Number yako', _bankAccountCtrl, Icons.account_balance,
                keyboard: TextInputType.number, required: true),
            const SizedBox(height: 6),
            if (_bankAccountCtrl.text.length >= 8) ...[
              Builder(builder: (_) {
                final bank = _detectBankFromAccount(_bankAccountCtrl.text);
                if (bank == null) {
                  return Text('⚠️ Account pattern haijulikani',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange));
                }
                return Row(children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Bank: $bank',
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: Colors.green.shade800)),
                ]);
              }),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _creating ? null : _createAndPay,
              icon: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                  _creating ? 'Inatuma...' : 'Weka & Lipa Deposit',
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
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
          ]
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b,
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedBank = v ?? 'NMB'),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1, TextInputType? keyboard, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Inahitajika';
        return null;
      },
    );
  }

  Widget _buildPayment(String serviceName) {
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
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9))),
                Text(_fmt(_countdown),
                    style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
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
                Text('$serviceName — Deposit',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('TSh ${_deposit.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text('Ref: $_bookingNumber',
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
                final uri =
                    Uri.parse('tel:${Uri.encodeComponent(ussdCode)}');
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
              onPressed: expired
                  ? null
                  : () => setState(() => _paidConfirmed = true),
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
                          builder: (_) => ServiceTrackingScreen(
                            bookingId: _bookingId!,
                            bookingNumber: _bookingNumber,
                            serviceName: serviceName,
                          ),
                        ),
                      );
                    },
                    child: Text('Fuatilia Booking',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
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
