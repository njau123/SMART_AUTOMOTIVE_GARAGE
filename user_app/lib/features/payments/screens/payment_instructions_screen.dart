import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class PaymentInstructionsScreen extends StatefulWidget {
  final double amount;
  final String purpose;
  final String reference;

  const PaymentInstructionsScreen({
    super.key,
    required this.amount,
    required this.purpose,
    required this.reference,
  });

  @override
  State<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentInstructionsScreenState extends State<PaymentInstructionsScreen> {
  final _phoneCtrl = TextEditingController();
  String _detectedNetwork = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _phoneCtrl.addListener(_detectNetwork);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    try {
      final profile = await AuthAPI.getProfile();
      if (!mounted) return;
      final phone = profile['phone_number']?.toString() ?? '';
      _phoneCtrl.text = phone;
      _detectNetwork();
    } catch (_) {}
  }

  // ============ NETWORK DETECTION ============
  void _detectNetwork() {
    final network = _detectNetworkFromPhone(_phoneCtrl.text);
    if (network != _detectedNetwork) {
      setState(() => _detectedNetwork = network);
    }
  }

  String _detectNetworkFromPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';

    String prefix = '';
    if (clean.startsWith('255')) {
      if (clean.length < 5) return '';
      prefix = '0${clean.substring(3, 5)}';
    } else if (clean.startsWith('0')) {
      if (clean.length < 3) return '';
      prefix = clean.substring(0, 3);
    } else {
      return '';
    }

    // Vodacom (M-Pesa)
    if (['075', '076', '071'].contains(prefix)) return 'Vodacom';
    // Tigo/Yas (Mixx by Yas)
    if (['065', '067', '077'].contains(prefix)) return 'Tigo/Yas';
    // Airtel Money
    if (['068', '069', '078'].contains(prefix)) return 'Airtel';
    // Halotel (HaloPesa)
    if (['061', '062'].contains(prefix)) return 'Halotel';
    // TTCL
    if (['073'].contains(prefix)) return 'TTCL';

    return 'Nyingine';
  }

  Map<String, dynamic> _networkInfo() {
    switch (_detectedNetwork) {
      case 'Vodacom':
        return {
          'name': 'Vodacom M-Pesa',
          'color': Colors.red,
          'icon': Icons.phone_android,
          'ussd': '*150*00#',
          'steps': [
            'Fungua app ya simu (Phone)',
            'Piga USSD: *150*00#',
            'Chagua "4. Lipa kwa M-Pesa"',
            'Chagua "2. Lipa kwa Namba ya Biashara"',
            'Weka namba: 0759212300',
            'Weka kiasi: TSh ${widget.amount.toStringAsFixed(0)}',
            'Weka reference: ${widget.reference}',
            'Weka PIN yako ya M-Pesa',
          ],
        };
      case 'Tigo/Yas':
        return {
          'name': 'Mixx by Yas (Tigo Pesa)',
          'color': Colors.blue,
          'icon': Icons.phone_android,
          'ussd': '*150*01#',
          'steps': [
            'Fungua app ya simu (Phone)',
            'Piga USSD: *150*01#',
            'Chagua "4. Lipa"',
            'Chagua "2. Lipa kwa Namba"',
            'Weka namba: 0759212300',
            'Weka kiasi: TSh ${widget.amount.toStringAsFixed(0)}',
            'Weka reference: ${widget.reference}',
            'Weka PIN yako ya Mixx',
          ],
        };
      case 'Airtel':
        return {
          'name': 'Airtel Money',
          'color': Colors.red.shade700,
          'icon': Icons.phone_android,
          'ussd': '*150*60#',
          'steps': [
            'Fungua app ya simu (Phone)',
            'Piga USSD: *150*60#',
            'Chagua "Pay Bill"',
            'Weka namba: 0759212300',
            'Weka kiasi: TSh ${widget.amount.toStringAsFixed(0)}',
            'Weka reference: ${widget.reference}',
            'Weka PIN yako ya Airtel Money',
          ],
        };
      case 'Halotel':
        return {
          'name': 'HaloPesa',
          'color': Colors.orange,
          'icon': Icons.phone_android,
          'ussd': '*150*88#',
          'steps': [
            'Fungua app ya simu (Phone)',
            'Piga USSD: *150*88#',
            'Chagua "Lipa"',
            'Weka namba: 0759212300',
            'Weka kiasi: TSh ${widget.amount.toStringAsFixed(0)}',
            'Weka reference: ${widget.reference}',
            'Weka PIN yako ya HaloPesa',
          ],
        };
      default:
        return {
          'name': 'Chagua Mtandao Wako',
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'ussd': '',
          'steps': [
            'Weka namba yako ya simu juu',
            'Mfumo utatambua mtandao wako',
            'Utapata maelekezo ya kulipa',
          ],
        };
    }
  }

  Future<void> _openDialer() async {
    final info = _networkInfo();
    final ussd = info['ussd'] as String;
    if (ussd.isEmpty) return;

    // Jaribu kufungua dialer na USSD
    final uri = Uri.parse('tel:${Uri.encodeComponent(ussd)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: copy USSD kwenye clipboard
        await Clipboard.setData(ClipboardData(text: ussd));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('USSD code imenakiliwa: $ussd'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: ussd));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('USSD code imenakiliwa: $ussd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ============ SUBMIT PAYMENT CONFIRMATION ============
  Future<void> _confirmPayment() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _snack('Weka namba yako ya simu', error: true);
      return;
    }
    if (_detectedNetwork.isEmpty || _detectedNetwork == 'Nyingine') {
      _snack('Mtandao wako hautambuliki', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Umekamilisha Malipo?'),
        content: const Text(
          'Baada ya kulipa, bonyeza "Ndiyo" ili admin athibitishe malipo yako.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bado'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Ndiyo, Nimelipa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final res = await PaymentAPI.submitReference(
        phoneNumber: _phoneCtrl.text.trim(),
        network: _detectedNetwork,
      );

      if (!mounted) return;
      if (res['success'] == true || res['status'] == 'PENDING') {
        _showSuccessDialog();
      } else {
        _snack(res['message']?.toString() ?? 'Imeshindikana', error: true);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(
              'Malipo Yamefanikiwa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tumepokea taarifa ya malipo yako. Admin atathibitisha hivi karibuni.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference: ${widget.reference}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Kiasi: TSh ${widget.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text(
              'Sawa',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _networkInfo();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Malipo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============ AMOUNT CARD ============
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kiasi cha Malipo',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'TSh ${widget.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.purpose,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============ PHONE INPUT ============
              Text(
                'Namba yako ya simu',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+255712345678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _detectedNetwork.isNotEmpty
                      ? Icon(
                          Icons.check_circle,
                          color: (info['color'] as Color),
                        )
                      : null,
                ),
              ),

              // ============ DETECTED NETWORK ============
              if (_detectedNetwork.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (info['color'] as Color).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        info['icon'] as IconData,
                        color: info['color'] as Color,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mtandao wako:',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              info['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: info['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((info['ussd'] as String).isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _openDialer,
                          icon: const Icon(Icons.phone, size: 16),
                          label: Text(info['ussd'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: info['color'] as Color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ============ PAYMENT DETAILS ============
              _copyCard(
                context,
                Icons.tag,
                'Reference',
                widget.reference,
                Colors.purple,
              ),
              const SizedBox(height: 10),
              _copyCard(
                context,
                Icons.phone,
                'Namba ya Malipo',
                '0759212300',
                Colors.green,
              ),
              const SizedBox(height: 10),
              _copyCard(
                context,
                Icons.account_balance,
                'NMB Account',
                '01112892839892',
                Colors.orange,
              ),
              const SizedBox(height: 10),
              _copyCard(
                context,
                Icons.person,
                'Jina la Akaunti',
                'AUTOMOTIVE SMART GARAGE CO. LTD',
                Colors.blue,
              ),
              const SizedBox(height: 20),

              // ============ STEPS ============
              if ((info['steps'] as List).isNotEmpty &&
                  _detectedNetwork != 'Nyingine') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            color: info['color'] as Color,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hatua za Malipo:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(info['steps'] as List<String>)
                          .asMap()
                          .entries
                          .map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: info['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ============ CONFIRM BUTTON ============
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Baada ya kulipa, bonyeza kitufe chini ili admin athibitishe.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _confirmPayment,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _submitting ? 'Inatuma...' : 'Nimelipa - Thibitisha',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _copyCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: color,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label imenakiliwa'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
