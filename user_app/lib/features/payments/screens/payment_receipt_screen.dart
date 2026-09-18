import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  const PaymentReceiptScreen({super.key, required this.payment});

  String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##0').format(n);

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
    final status = payment['status']?.toString() ?? 'PENDING';
    final reference = payment['reference']?.toString() ?? '—';
    final purpose = payment['purpose']?.toString() ?? 'PAYMENT';
    final method = payment['method']?.toString() ?? 'MOBILE_MONEY';
    final provider = payment['provider']?.toString() ?? 'SANDBOX';
    final phone = payment['phone_number']?.toString() ?? '—';
    final date = payment['created_at']?.toString() ?? '';

    String formattedDate = date;
    try {
      formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(date));
    } catch (_) {}

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.hourglass_bottom;
    if (status.toUpperCase() == 'SUCCESS' || status.toUpperCase() == 'COMPLETED') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.toUpperCase() == 'FAILED' || status.toUpperCase() == 'CANCELLED') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Risiti ya Malipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference imenakiliwa'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AUTOMOTIVE SMART GARAGE',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Company Limited',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Afya ya Gari Yako ni Jukumu Letu',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'TSh ${_fmt(amount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRow('Reference', reference),
                    _buildRow('Aina', purpose),
                    _buildRow('Njia', method.replaceAll('_', ' ')),
                    _buildRow('Provider', provider),
                    if (phone != '—') _buildRow('Namba', phone),
                    _buildRow('Tarehe', formattedDate),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 14),
                    Text(
                      'Asante kwa kutumia huduma zetu',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automotive Smart Garage Co. Ltd',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Maji Chumvi, Dar es Salaam',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final text = 'RISITI YA MALIPO\n'
                        'Automotive Smart Garage Co. Ltd\n'
                        '---\n'
                        'Reference: $reference\n'
                        'Kiasi: TSh ${_fmt(amount)}\n'
                        'Aina: $purpose\n'
                        'Njia: $method\n'
                        'Tarehe: $formattedDate\n'
                        'Hali: $status\n'
                        '---\n'
                        'Asante!';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Risiti imenakiliwa')),
                    );
                  },
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Nakili Risiti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
