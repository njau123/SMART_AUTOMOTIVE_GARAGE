import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/skeleton.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  List<dynamic> _payments = [];

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
      final results = await Future.wait([
        WalletAPI.getWallet(),
        WalletAPI.getTransactions(),
        PaymentAPI.getMyPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List<dynamic>;
        _payments = results[2] as List<dynamic>;
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

  double get _balance {
    final b = _wallet?['balance'];
    return double.tryParse(b?.toString() ?? '0') ?? 0;
  }

  double get _pendingTotal {
    double total = 0;
    for (final p in _payments) {
      if (p is Map && p['status'] == 'PENDING') {
        total += double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline, size: 64, color: AppColors.danger),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _load,
            child: const Text('Jaribu Tena'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salio Lako',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'TSh ${_balance.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_pendingTotal > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Malipo yanayosubiri: TSh ${_pendingTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Pending Payments
        if (_payments.where((p) => p is Map && p['status'] == 'PENDING').isNotEmpty) ...[
          _sectionTitle('Malipo Yanayosubiri'),
          const SizedBox(height: 8),
          ..._payments
              .where((p) => p is Map && p['status'] == 'PENDING')
              .map((p) => _paymentCard(p as Map))
              .toList(),
          const SizedBox(height: 20),
        ],

        // Transactions
        _sectionTitle('Historia ya Malipo'),
        const SizedBox(height: 8),
        if (_transactions.isEmpty && _payments.isEmpty)
          _emptyState()
        else
          ..._transactions.map((t) => _transactionCard(t as Map)).toList(),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _paymentCard(Map p) {
    final amount = p['amount']?.toString() ?? '0';
    final purpose = p['purpose']?.toString() ?? 'Payment';
    final reference = p['reference']?.toString() ?? '—';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.pending_actions, color: Colors.orange),
        ),
        title: Text(
          'TSh $amount',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$purpose\nRef: $reference',
          style: GoogleFonts.poppins(fontSize: 11),
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text('PENDING',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.orange)),
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _transactionCard(Map t) {
    final amount = t['amount']?.toString() ?? '0';
    final type = t['type']?.toString() ?? t['description']?.toString() ?? 'Transaction';
    final date = t['created_at']?.toString() ?? '';
    String formatted = date;
    try {
      final d = DateTime.parse(date);
      formatted = DateFormat('dd MMM yyyy, HH:mm').format(d);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.primary),
        ),
        title: Text(
          'TSh $amount',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$type\n$formatted',
          style: GoogleFonts.poppins(fontSize: 11),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.wallet_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Hakuna malipo bado',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
