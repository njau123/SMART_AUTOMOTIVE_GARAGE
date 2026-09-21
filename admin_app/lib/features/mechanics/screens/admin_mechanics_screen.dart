import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});
  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  List<dynamic> _mechanics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getMechanics();
      if (mounted) setState(() { _mechanics = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(dynamic m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa Mechanic?'),
        content: Text('Una uhakika kumfuta "${m['full_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final res = await AdminMechanicAPI.delete(m['id'] as int);
        if (mounted && res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']?.toString() ?? 'Imefutwa'),
                backgroundColor: Colors.green),
          );
          _load();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MechanicFormScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mechanics'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Ongeza Mechanic'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mechanics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.engineering_outlined,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Hakuna mechanics bado',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Bonyeza "+" kuongeza mpya'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _mechanics.length,
                    itemBuilder: (_, i) {
                      final m = _mechanics[i];
                      final regNo = m['verification_documents'] is Map
                          ? (m['verification_documents']['registration_number']?.toString() ?? '')
                          : '';
                      final isActive = m['is_active'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive ? AppColors.primary : Colors.grey,
                            child: const Icon(Icons.engineering, color: Colors.white),
                          ),
                          title: Text(m['full_name']?.toString() ?? '-'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (regNo.isNotEmpty)
                                Text('Reg: $regNo',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              Text('${m['expertise'] ?? '-'} • ${m['region'] ?? '-'}',
                                  style: GoogleFonts.poppins(fontSize: 11)),
                              Text('Simu: ${m['phone_number'] ?? '-'}',
                                  style: GoogleFonts.poppins(fontSize: 11)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(m),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


// ==================== FORM SCREEN ====================
class MechanicFormScreen extends StatefulWidget {
  const MechanicFormScreen({super.key});
  @override
  State<MechanicFormScreen> createState() => _MechanicFormScreenState();
}

class _MechanicFormScreenState extends State<MechanicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specialistCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _specialistCtrl.dispose();
    _regionCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await AdminMechanicAPI.create(
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        specialist: _specialistCtrl.text.trim(),
        region: _regionCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res['success'] == true) {
        final regNo = res['data']?['registration_number']?.toString() ?? '';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Mechanic Amefanikiwa ✅'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registration Number:',
                    style: GoogleFonts.poppins(fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(regNo,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mpe mechanic hii namba ili a-activate account yake kwenye mechanic app.',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Sawa'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Imeshindwa'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ongeza Mechanic')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
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
                          'Unda record ya mechanic. Mfumo utatoa ME-XXXX. '
                          'Mechanic ata-activate kwa kujisajili kwenye mechanic app.',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Majina yote matatu',
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
                TextFormField(
                  controller: _specialistCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Specialist (mfano Engine, Wiring)',
                    prefixIcon: Icon(Icons.build),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Ni lazima' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _regionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mkoa (mfano Dar es Salaam)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Ni lazima' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Wilaya (hiari)',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? 'Inahifadhi...' : 'Hifadhi Mechanic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
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
