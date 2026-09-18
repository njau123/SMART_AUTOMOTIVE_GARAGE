
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _subjectCtrl.dispose(); _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ContactAPI.sendMessage(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ujumbe umetumwa! Tutawasiliana nawe."),
          backgroundColor: Colors.green,
        ));
        _subjectCtrl.clear(); _messageCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res["message"]?.toString() ?? "Imeshindikana"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Contact Us")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Jina lako", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? "Ni lazima" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Email ni lazima";
                    if (!v.contains("@")) return "Email si sahihi";
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Namba ya simu", prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(labelText: "Kichwa", prefixIcon: Icon(Icons.subject_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: "Ujumbe wako", prefixIcon: Icon(Icons.message_outlined), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? "Ni lazima" : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Text("Tuma Ujumbe"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
