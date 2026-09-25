import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/auth_state.dart';
import '../../mechanics/screens/mechanics_screen.dart';

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

  Uint8List? _imageBytes;
  String? _imageName;
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

  String get _userName {
    final f = AuthState.instance.user?['first_name']?.toString() ?? '';
    return f.isEmpty ? 'Driver' : f;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await MethodsAPI.diagnoseWithImage(
        vehicleMake: _make.text.trim(),
        vehicleModel: _model.text.trim(),
        vehicleYear: _year.text.trim(),
        symptoms: _symptoms.text.trim(),
        imageBytes: _imageBytes,
        imageName: _imageName,
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

  void _goToMechanics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MechanicsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            // GREETING
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello $_userName! 👋',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              'What\'s wrong with your car today?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // IMAGE UPLOAD
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _imageBytes = null;
                                _imageName = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text('Upload picha ya shida (optional)',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('AI itaichambua picha yako',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Vehicle Make'),
            TextFormField(
              controller: _make,
              decoration: const InputDecoration(
                  hintText: 'e.g. Toyota',
                  prefixIcon: Icon(Icons.directions_car_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Model'),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                  hintText: 'e.g. Corolla',
                  prefixIcon: Icon(Icons.directions_car_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Year'),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'e.g. 2018',
                  prefixIcon: Icon(Icons.calendar_today_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Symptoms'),
            TextFormField(
              controller: _symptoms,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText:
                      'e.g. gari linazima ghafla, check engine light ipo...',
                  alignLabelWithHint: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                label: Text(_loading ? 'AI inachambua...' : 'Run AI Diagnosis'),
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
    final summary = _result?['summary']?.toString() ?? '';
    final severity = _result?['severity']?.toString() ?? 'MEDIUM';
    final detailed = _result?['detailed_explanation']?.toString() ?? '';

    final severityColor = severity == 'CRITICAL'
        ? Colors.red.shade900
        : severity == 'HIGH'
            ? Colors.red
            : severity == 'MEDIUM'
                ? Colors.orange
                : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SUMMARY
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: severityColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: severityColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('AI Diagnosis Complete',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(severity,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ],
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(summary,
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (causes.isNotEmpty) ...[
          _sectionTitle('🔍 Sababu Zinazowezekana'),
          ...causes.map((c) => _bullet(c.toString())),
          const SizedBox(height: 16),
        ],
        if (actions.isNotEmpty) ...[
          _sectionTitle('🔧 Hatua za Kuchukua'),
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
                    Text('⚠️ Tahadhari za Usalama',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                ...warnings.map((w) =>
                    _bullet(w.toString(), color: AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (detailed.isNotEmpty) ...[
          _sectionTitle('📖 Maelezo ya Kina'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(detailed,
                style: GoogleFonts.poppins(fontSize: 13, height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (specialty.isNotEmpty) ...[
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
          const SizedBox(height: 24),
        ],

        // FIND MECHANIC BUTTON
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you\'re not satisfied with our AI diagnosis analysis, you may find out our mechanic.',
                style: GoogleFonts.poppins(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _goToMechanics,
                  icon: const Icon(Icons.engineering, size: 18),
                  label: const Text('Find a Mechanic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
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
                      fontSize: 13, height: 1.5, color: color)),
            ),
          ],
        ),
      );
}
