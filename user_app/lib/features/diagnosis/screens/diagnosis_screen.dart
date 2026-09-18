import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../payments/screens/payment_screen.dart';
import '../../../core/state/auth_state.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _symptoms = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = AuthState.instance.user?['vehicle'];
    if (v is Map) {
      _make.text = v['make']?.toString() ?? '';
      _model.text = v['model']?.toString() ?? '';
      _year.text = v['year']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await MethodsAPI.diagnose(
        vehicleMake: _make.text.trim(),
        vehicleModel: _model.text.trim(),
        vehicleYear: _year.text.trim(),
        symptoms: _symptoms.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : Map<String, dynamic>.from(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI Diagnosis'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Diagnosis',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Describe symptoms — get instant analysis',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _label('Vehicle Make'),
            TextFormField(
              controller: _make,
              decoration: const InputDecoration(
                  hintText: 'e.g. Toyota',
                  prefixIcon: Icon(Icons.directions_car_outlined)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Model'),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                  hintText: 'e.g. Corolla',
                  prefixIcon: Icon(Icons.directions_car_outlined)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Year'),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'e.g. 2018',
                  prefixIcon: Icon(Icons.calendar_today_outlined)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Symptoms'),
            TextFormField(
              controller: _symptoms,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText:
                      'e.g. gari linazima ghafla, check engine light ipo, sauti ya kawaida...',
                  alignLabelWithHint: true),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Icon(Icons.auto_awesome_outlined, size: 20),
                label: Text(_loading ? 'Analyzing...' : 'Run Diagnosis'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.danger)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _resultView(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _payForDiagnosis() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentScreen(
          amount: 5000,
          purpose: 'SERVICE',
          title: 'AI Car Scanner - Siku ya Ziada',
          referenceId: 'AI_SCANNER_DAILY',
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Malipo yameanzishwa. Admin atathibitisha ili kuendelea kutumia AI Scanner.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _resultView() {
    final causes = (_result?['possible_causes'] as List?) ?? [];
    final actions = (_result?['recommended_actions'] as List?) ?? [];
    final warnings = (_result?['safety_warnings'] as List?) ?? [];
    final specialty = _result?['mechanic_specialty']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Analysis complete',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (causes.isNotEmpty) ...[
          _sectionTitle('Possible causes'),
          ...causes.map((c) => _bullet(c.toString())),
          const SizedBox(height: 16),
        ],
        if (actions.isNotEmpty) ...[
          _sectionTitle('Recommended actions'),
          ...actions.map((a) => _bullet(a.toString())),
          const SizedBox(height: 16),
        ],
        if (warnings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text('Safety warnings',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                ...warnings.map((w) => _bullet(w.toString(),
                    color: AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (specialty.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.engineering_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Recommended: $specialty',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700)),
      );

  Widget _bullet(String t, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      color: color)),
            ),
          ],
        ),
      );
}
