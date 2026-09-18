import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
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
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _snack("Weka namba yako ya simu", error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await PaymentAPI.initiate(
        amount: widget.amount,
        purpose: widget.purpose,
        phoneNumber: phone,
        description: widget.title,
        referenceId: widget.referenceId ?? "",
      );
      if (!mounted) return;
      if (res["success"] == true) {
        _showSuccessDialog(res);
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

  void _showSuccessDialog(Map<String, dynamic> res) {
    final instructions = res["instructions"]?.toString() ?? "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Text("Malipo Yameanzishwa",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Malipo yameanzishwa kikamilifu.",
                style: GoogleFonts.poppins(fontSize: 14)),
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
                        : "Weka namba yako ya Siri ili kuthibitisha malipo kwenda Automotive Smart Garage Account.",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text("Admin atathibitisha malipo yako hivi karibuni.",
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
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
              Text("Namba yako ya simu",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "+255712345678 au 0759212300",
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      "1. Bonyeza 'Lipa Sasa'\n2. Utapewa maelekezo ya malipo\n3. Weka namba yako ya Siri\n4. Admin atathibitisha malipo yako",
                      style: GoogleFonts.poppins(fontSize: 12, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
}
