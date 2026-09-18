import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tanzania_regions.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  // Region
  String? _selectedRegion;

  // Vehicle
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleReg = TextEditingController();

  // Security
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _agree = false;

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _vehicleYear.dispose();
    _vehicleReg.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null) {
      _snack('Please select your region', error: true);
      return;
    }
    if (!_agree) {
      _snack('Please accept the Terms & Conditions', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await AuthAPI.register(
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _pass.text,
        region: _selectedRegion ?? '',
        vehicleMake: _vehicleMake.text.trim(),
        vehicleModel: _vehicleModel.text.trim(),
        vehicleYear: _vehicleYear.text.trim(),
        vehicleRegistration: Validators.formatReg(_vehicleReg.text.trim()),
      );

      if (!mounted) return;
      if (data['success'] == true) {
        _successDialog();
      } else {
        _snack(
          data['message']?.toString() ?? 'Registration failed',
          error: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
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

  void _successDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text('Success',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Registration successful! You may continue to login.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Signup
            },
            child: Text(
              'Sign in',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create account',
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Join Smart Automotive Garage',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),

                    // ===== Personal Information =====
                    _section('Personal Information'),
                    const SizedBox(height: 10),
                    _card([
                      Row(children: [
                        Expanded(
                          child: _field(
                            'First name',
                            _firstName,
                            Icons.person_outline,
                            validator: (v) => Validators.name(v, field: 'First name'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Middle name',
                            _middleName,
                            Icons.person_outline,
                            validator: (v) =>
                                Validators.name(v, field: 'Middle name', required: false),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _field(
                        'Last name',
                        _lastName,
                        Icons.person_outline,
                        validator: (v) => Validators.name(v, field: 'Last name'),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'Email',
                        _email,
                        Icons.mail_outline,
                        keyboard: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'Phone (06XXXXXXXX au 07XXXXXXXX)',
                        _phone,
                        Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: Validators.phoneTanzania,
                      ),
                    ]),

                    // ===== Region =====
                    const SizedBox(height: 18),
                    _section('Region'),
                    const SizedBox(height: 10),
                    _card([
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRegion,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select your region',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                        items: TanzaniaRegions.all
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRegion = v),
                        validator: (v) =>
                            v == null ? 'Please select your region' : null,
                      ),
                    ]),

                    // ===== Vehicle Information =====
                    const SizedBox(height: 18),
                    _section('Vehicle Information'),
                    const SizedBox(height: 10),
                    _card([
                      Row(children: [
                        Expanded(
                          child: _field(
                            'Make (Toyota)',
                            _vehicleMake,
                            Icons.directions_car_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Model (Corolla)',
                            _vehicleModel,
                            Icons.directions_car_outlined,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _field(
                            'Year (2013)',
                            _vehicleYear,
                            Icons.calendar_today_outlined,
                            keyboard: TextInputType.number,
                            validator: Validators.vehicleYear,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Reg No. (T123 ABC)',
                            _vehicleReg,
                            Icons.badge_outlined,
                            validator: Validators.vehicleRegTanzania,
                          ),
                        ),
                      ]),
                    ]),

                    // ===== Security =====
                    const SizedBox(height: 18),
                    _section('Security'),
                    const SizedBox(height: 10),
                    _card([
                      _passwordField('Password', _pass, Validators.password),
                      const SizedBox(height: 12),
                      _passwordField(
                        'Confirm password',
                        _confirm,
                        (v) {
                          if (v != _pass.text) return "Passwords don't match";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Checkbox(
                          value: _agree,
                          onChanged: (v) => setState(() => _agree = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms & Conditions',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ]),
                    ]),

                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600));

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(icon, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator ??
              (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              },
        ),
      ],
    );
  }

  Widget _passwordField(
      String label, TextEditingController ctrl, String? Function(String?) validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
