import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminSparePartsScreen extends StatefulWidget {
  const AdminSparePartsScreen({super.key});
  @override
  State<AdminSparePartsScreen> createState() => _AdminSparePartsScreenState();
}

class _AdminSparePartsScreenState extends State<AdminSparePartsScreen> {
  List<dynamic> _parts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getSpareParts();
      if (mounted) setState(() { _parts = data; _loading = false; });
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
      builder: (_) => _SparePartForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(dynamic part) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Spare Part?"),
        content: Text("Una uhakika unataka kufuta '${part['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hapana")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ndiyo, Futa"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AdminAPI.deleteSparePart(part['id'] as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Spare part imefutwa"), backgroundColor: Colors.green),
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
        title: const Text('Spare Parts'),
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
          : _parts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text("Hakuna spare parts", style: GoogleFonts.poppins()),
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
                    itemCount: _parts.length,
                    itemBuilder: (_, i) {
                      final p = _parts[i];
                      final img = p['main_image']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: img.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    img, width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50, height: 50, color: AppColors.border,
                                      child: const Icon(Icons.settings),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.settings, color: AppColors.primary),
                                ),
                          title: Text(p['name']?.toString() ?? 'Unnamed'),
                          subtitle: Text("TSh ${p['price'] ?? '0'} • Stock: ${p['stock_quantity'] ?? 0}"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openForm(Map<String, dynamic>.from(p as Map));
                              if (v == 'delete') _delete(p);
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

class _SparePartForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _SparePartForm({this.existing});
  @override
  State<_SparePartForm> createState() => _SparePartFormState();
}

class _SparePartFormState extends State<_SparePartForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _partNumberCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  XFile? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!['name']?.toString() ?? '';
      _descCtrl.text = widget.existing!['description']?.toString() ?? '';
      _priceCtrl.text = widget.existing!['price']?.toString() ?? '';
      _brandCtrl.text = widget.existing!['brand']?.toString() ?? '';
      _partNumberCtrl.text = widget.existing!['part_number']?.toString() ?? '';
      _stockCtrl.text = widget.existing!['stock_quantity']?.toString() ?? '0';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = picked);
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
      // Convert XFile → bytes (web-compatible)
      List<int>? imageBytes;
      String? imageName;
      if (_image != null) {
        imageBytes = await _image!.readAsBytes();
        imageName = _image!.name;
      }

      if (widget.existing == null) {
        await AdminAPI.createSparePart(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text) ?? 0,
          brand: _brandCtrl.text.trim(),
          partNumber: _partNumberCtrl.text.trim(),
          stock: int.tryParse(_stockCtrl.text) ?? 0,
          imageBytes: imageBytes,
          imageName: imageName,
        );
      } else {
        await AdminAPI.updateSparePart(
          id: widget.existing!['id'] as int,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text) ?? 0,
          brand: _brandCtrl.text.trim(),
          partNumber: _partNumberCtrl.text.trim(),
          stock: int.tryParse(_stockCtrl.text) ?? 0,
          imageBytes: imageBytes,
          imageName: imageName,
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
    _brandCtrl.dispose();
    _partNumberCtrl.dispose();
    _stockCtrl.dispose();
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
            Text(isEdit ? "Hariri Spare Part" : "Ongeza Spare Part Mpya",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Jina la Spare Part", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Maelezo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Bei (TSh)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: "Brand / Mtengenezaji", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partNumberCtrl,
              decoration: const InputDecoration(labelText: "Part Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock / Idadi iliyopo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_image == null ? "Chagua Picha" : "Badilisha Picha"),
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              FutureBuilder<List<int>>(
                future: _image!.readAsBytes(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(snapshot.data!),
                      height: 120, fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
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
