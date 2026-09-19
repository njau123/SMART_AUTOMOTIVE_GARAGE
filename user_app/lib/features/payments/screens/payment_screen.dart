import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String purpose;
  final String title;
  final String? referenceId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.purpose,
    required this.title,
    this.referenceId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _methodType = 'MOBILE_MONEY'; // 'MOBILE_MONEY' au 'BANK'
  final _identifierCtrl = TextEditingController();
  bool _loading = false;

  // Optional overrides
  String? _networkOverride;
  String? _bankOverride;

  final _networks = ['Vodacom', 'Tigo/Yas', 'Airtel', 'Halotel', 'TTCL'];
  final _banks = ['NMB', 'CRDB', 'Azania', 'NBC'];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    try {
      final profile = await AuthAPI.getProfile();
      if (!mounted) return;
      final phone = profile['phone_number']?.toString() ?? '';
      if (phone.isNotEmpty) {
        _identifierCtrl.text = phone;
      }
    } catch (_) {}
  }

  Future<void> _pay() async {
    final identifier = _identifierCtrl.text.trim();
    if (identifier.isEmpty) {
      _snack(
        _methodType == 'MOBILE_MONEY'
            ? "Weka namba yako ya simu"
            : "Weka account au card number",
        error: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await PaymentAPI.initiateUnified(
        amount: widget.amount,
        purpose: widget.purpose,
        methodType: _methodType,
        identifier: identifier,
        networkOverride: _networkOverride,
        bankOverride: _bankOverride,
        description: widget.title,
        referenceId: widget.referenceId ?? "",
      );

      if (!mounted) return;
      if (res["success"] == true) {
        _showInstructionsDialog(res);
      } else {
        _snack(res["message"]?.toString() ?? "Imeshindikana", error: true);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll("Exception: ", ""), error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInstructionsDialog(Map<String, dynamic> res) {
    final instructions = res["instructions"]?.toString() ?? "";
    final data = res["data"] as Map? ?? {};
    final reference = data["reference"]?.toString() ?? "";
    final detected = data["detected_network_or_bank"]?.toString() ?? "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text("Malipo Yameanzishwa",
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
              if (detected.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Imegundulika: $detected",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
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
                    Text("Maelekezo:",
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
              if (reference.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Kumbukumbu: $reference",
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: reference));
                        if (mounted) {
                          _snack("Reference imenakiliwa");
                        }
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                "Admin atathibitisha malipo yako hivi karibuni. "
                "Unaweza kuona hali ya malipo kwenye 'Historia ya Malipo'.",
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text("Sawa",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Malipo")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== AMOUNT CARD =====
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
                    Text("Kiasi cha Malipo",
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Text("TSh ${widget.amount.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== METHOD TYPE SELECTION =====
              Text("Chagua njia ya kulipia",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _methodCard(
                      title: "Simu",
                      subtitle: "M-Pesa, Tigo, Airtel, Halotel",
                      icon: Icons.phone_android,
                      isSelected: _methodType == 'MOBILE_MONEY',
                      onTap: () => setState(() {
                        _methodType = 'MOBILE_MONEY';
                        _networkOverride = null;
                        _bankOverride = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _methodCard(
                      title: "Benki",
                      subtitle: "NMB, CRDB, Azania, NBC",
                      icon: Icons.account_balance,
                      isSelected: _methodType == 'BANK',
                      onTap: () => setState(() {
                        _methodType = 'BANK';
                        _networkOverride = null;
                        _bankOverride = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== IDENTIFIER FIELD =====
              Text(
                _methodType == 'MOBILE_MONEY'
                    ? "Namba yako ya simu"
                    : "Account au Card number",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _identifierCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _methodType == 'MOBILE_MONEY'
                      ? "+255712345678 au 0759212300"
                      : "Mfano: 23210042232",
                  prefixIcon: Icon(
                    _methodType == 'MOBILE_MONEY'
                        ? Icons.phone_outlined
                        : Icons.credit_card,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ===== OVERRIDE DROPDOWN =====
              if (_methodType == 'MOBILE_MONEY') ...[
                Text("Mtandao (kama unataka kubadilisha)",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _networkOverride,
                  decoration: InputDecoration(
                    hintText: "Auto-detect",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text("Auto-detect")),
                    ..._networks.map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(n),
                        )),
                  ],
                  onChanged: (v) => setState(() => _networkOverride = v),
                ),
              ] else ...[
                Text("Benki (kama unataka kubadilisha)",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _bankOverride,
                  decoration: InputDecoration(
                    hintText: "Auto-detect",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text("Auto-detect")),
                    ..._banks.map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b),
                        )),
                  ],
                  onChanged: (v) => setState(() => _bankOverride = v),
                ),
              ],
              const SizedBox(height: 24),

              // ===== INFO BOX =====
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text("Jinsi ya Kulipa",
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "1. Bonyeza 'Lipa Sasa'\n"
                      "2. Utapewa maelekezo ya malipo\n"
                      "3. Lipa kwa USSD au app ya benki\n"
                      "4. Admin atathibitisha malipo yako\n"
                      "5. Utapata notification mara moja",
                      style: GoogleFonts.poppins(fontSize: 12, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== PAY BUTTON =====
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text("Lipa Sasa",
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

  Widget _methodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 28),
            const SizedBox(height: 6),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
