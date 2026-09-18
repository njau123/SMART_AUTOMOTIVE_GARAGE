import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final data = await EarningsAPI.getEarnings();
      setState(() => _data = data);
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _data?['total_earnings'] ?? '0';
    final history = _data?['history'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Earnings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Total Earnings', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('TZS $total', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(
          child: history.isEmpty
              ? const Center(child: Text('No payments yet'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, i) {
                    final tx = history[i];
                    return ListTile(
                      leading: const Icon(Icons.payment, color: AppTheme.primary),
                      title: Text(tx['reference'] ?? 'Payment'),
                      subtitle: Text('${tx['type']} - ${tx['created_at'] ?? ''}'),
                      trailing: Text('TZS ${tx['amount']}'),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
