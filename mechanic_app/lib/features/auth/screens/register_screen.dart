import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/tanzania_regions.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNoCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedRegion;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _regNoCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthAPI.activate(
        registrationNumber: _regNoCtrl.text.trim().toUpperCase(),
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passCtrl.text,
        region: _selectedRegion ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akaunti yako ime-activate! Karibu.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Activate Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Weka taarifa ulizopewa na admin wakati wa kusajiliwa. '
                          'Ukisha-activate, utaweza kuingia kwa ME number yako.',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _regNoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'ME Number (mfano ME-4158)',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                    hintText: 'ME-XXXX',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'ME number ni lazima';
                    if (!v.toUpperCase().startsWith('ME-')) {
                      return 'Lazima ianze na ME-';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Majina yote (kama yalivyosajiliwa)',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Ni lazima' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Namba ya Simu (+255XXXXXXXXX)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ni lazima';
                    if (!v.startsWith('+255')) return 'Anza na +255';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mkoa wako',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: TanzaniaRegions.all
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRegion = v),
                  validator: (v) => v == null || v.isEmpty ? 'Chagua mkoa' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email yako',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email ni lazima';
                    if (!v.contains('@')) return 'Email si sahihi';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password (herufi 6+)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password ni lazima';
                    if (v.length < 6) return 'Angalau herufi 6';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Rudia password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Password hazifanani';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _activate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : Text('Activate Account',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text('Una account? Ingia hapa',
                      style: GoogleFonts.poppins(color: Colors.blue.shade700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
