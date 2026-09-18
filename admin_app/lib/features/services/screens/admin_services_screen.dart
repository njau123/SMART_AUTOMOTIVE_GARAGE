import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<dynamic> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getServices();
      if (mounted) setState(() { _services = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServiceForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(dynamic s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Service?"),
        content: Text("Una uhakika kufuta '${s['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hapana")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ndiyo"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AdminAPI.deleteService(s['id'] as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Service imefutwa"), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text("Ongeza"),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.build_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text("Hakuna services", style: GoogleFonts.poppins()),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text("Ongeza ya Kwanza"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _services.length,
                    itemBuilder: (_, i) {
                      final s = _services[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.build, color: AppColors.primary),
                          ),
                          title: Text(s['name']?.toString() ?? 'Unnamed'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['description']?.toString() ?? ''),
                              Text("TSh ${s['base_price'] ?? '0'} • ${s['estimated_duration_minutes'] ?? 0} min"),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openForm(Map<String, dynamic>.from(s as Map));
                              if (v == 'delete') _delete(s);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text("Hariri")),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text("Futa", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ServiceForm({this.existing});
  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!['name']?.toString() ?? '';
      _descCtrl.text = widget.existing!['description']?.toString() ?? '';
      _priceCtrl.text = widget.existing!['base_price']?.toString() ?? '';
      _durationCtrl.text = widget.existing!['estimated_duration_minutes']?.toString() ?? '60';
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jina na bei ni lazima"), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await AdminAPI.createService(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          basePrice: double.tryParse(_priceCtrl.text) ?? 0,
          estimatedMinutes: int.tryParse(_durationCtrl.text) ?? 60,
        );
      } else {
        await AdminAPI.updateService(
          id: widget.existing!['id'] as int,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          basePrice: double.tryParse(_priceCtrl.text) ?? 0,
          estimatedMinutes: int.tryParse(_durationCtrl.text) ?? 60,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? "Hariri Service" : "Ongeza Service Mpya",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Jina la Service", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: "Maelezo", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Bei (TSh)", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _durationCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Muda (dakika)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Hifadhi" : "Ongeza"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
