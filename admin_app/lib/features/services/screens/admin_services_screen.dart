import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<dynamic> _services = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final services = await AdminAPI.getServices();
      List<dynamic> categories = [];
      try {
        categories = await AdminAPI.getServiceCategories();
      } catch (e) {
        debugPrint('Categories error: $e');
      }
      if (mounted) {
        setState(() {
          _services = services;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServiceForm(existing: existing, categories: _categories),
    );
    if (result == true) _load();
  }

  Future<void> _delete(dynamic s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Service?"),
        content: Text("Una uhakika kufuta '${s['name']}'? Users wote wataarifiwa."),
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
        await AdminAPI.deleteService(s['id'] as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Service imefutwa + users wamearifiwa"), backgroundColor: Colors.green),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text("Ongeza"),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins()),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text("Jaribu Tena")),
                      ],
                    ),
                  ),
                )
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
                          final img = (s['image'] ?? '').toString();
                          final days = (s['available_days'] is List)
                              ? (s['available_days'] as List).join(', ')
                              : '';
                          final timeRange = (s['start_time'] != null && s['end_time'] != null)
                              ? '${s['start_time'].toString().substring(0, 5)} - ${s['end_time'].toString().substring(0, 5)}'
                              : '';
                          final hasVideo = (s['video'] ?? '').toString().isNotEmpty;

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
                                          child: const Icon(Icons.build),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.build, color: AppColors.primary),
                                    ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(s['name']?.toString() ?? 'Unnamed')),
                                  if (hasVideo)
                                    const Icon(Icons.videocam, size: 18, color: Colors.red),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['category_name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                  Text(s['description']?.toString() ?? '',
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text("TSh ${s['base_price'] ?? '0'}"),
                                  if (days.isNotEmpty)
                                    Text("Siku: $days",
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  if (timeRange.isNotEmpty)
                                    Text("Muda: $timeRange",
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _openForm(Map<String, dynamic>.from(s as Map));
                                  }
                                  if (v == 'delete') {
                                    _delete(s);
                                  }
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

// ==================== SERVICE FORM ====================
class _ServiceForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<dynamic> categories;
  const _ServiceForm({this.existing, required this.categories});
  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  int? _categoryId;
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _videoBytes;
  String? _videoName;
  bool _fixedPrice = false;
  bool _saving = false;

  final _picker = ImagePicker();

  final _allDays = [
    {'code': 'MON', 'name': 'Jumatatu'},
    {'code': 'TUE', 'name': 'Jumanne'},
    {'code': 'WED', 'name': 'Jumatano'},
    {'code': 'THU', 'name': 'Alhamisi'},
    {'code': 'FRI', 'name': 'Ijumaa'},
    {'code': 'SAT', 'name': 'Jumamosi'},
    {'code': 'SUN', 'name': 'Jumapili'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e['name']?.toString() ?? '';
      _descCtrl.text = e['description']?.toString() ?? '';
      _priceCtrl.text = e['base_price']?.toString() ?? '';
      if (e['category'] is int) _categoryId = e['category'] as int;
      if (e['available_days'] is List) {
        _selectedDays = List<String>.from(
          (e['available_days'] as List).map((d) => d.toString()),
        );
      }
      _fixedPrice = e['fixed_price'] == true;

      final st = e['start_time']?.toString();
      if (st != null && st.contains(':')) {
        final p = st.split(':');
        _startTime = TimeOfDay(
          hour: int.tryParse(p[0]) ?? 0,
          minute: int.tryParse(p[1].substring(0, 2)) ?? 0,
        );
      }
      final et = e['end_time']?.toString();
      if (et != null && et.contains(':')) {
        final p = et.split(':');
        _endTime = TimeOfDay(
          hour: int.tryParse(p[0]) ?? 0,
          minute: int.tryParse(p[1].substring(0, 2)) ?? 0,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() { _imageBytes = bytes; _imageName = x.name; });
      }
    } catch (e) {
      _snack("Imeshindwa kuchagua picha: $e", error: true);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video, withData: true, allowMultiple: false,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _videoBytes = result.files.single.bytes;
          _videoName = result.files.single.name;
        });
      }
    } catch (e) {
      _snack("Imeshindwa kuchagua video: $e", error: true);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      _snack("Jina na bei ni lazima", error: true);
      return;
    }
    if (_categoryId == null) {
      _snack("Chagua category", error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final isEdit = widget.existing != null;

      if (!isEdit) {
        await AdminAPI.createService(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          basePrice: double.tryParse(_priceCtrl.text) ?? 0,
          categoryId: _categoryId,
          imageBytes: _imageBytes,
          imageName: _imageName,
          videoBytes: _videoBytes,
          videoName: _videoName,
          availableDays: _selectedDays,
          startTime: _fmtTime(_startTime),
          endTime: _fmtTime(_endTime),
          fixedPrice: _fixedPrice,
        );
      } else {
        await AdminAPI.updateService(
          id: widget.existing!['id'] as int,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          basePrice: double.tryParse(_priceCtrl.text) ?? 0,
          categoryId: _categoryId,
          imageBytes: _imageBytes,
          imageName: _imageName,
          videoBytes: _videoBytes,
          videoName: _videoName,
          availableDays: _selectedDays,
          startTime: _fmtTime(_startTime),
          endTime: _fmtTime(_endTime),
          fixedPrice: _fixedPrice,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      _snack(isEdit ? "Service imeupdate" : "Service imeongezwa + users wamearifiwa");
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
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

            // ===== IMAGE PICKER =====
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: 140, height: 140),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, size: 40, color: AppColors.primary),
                            const SizedBox(height: 6),
                            Text('Chagua Picha',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ===== VIDEO PICKER =====
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(_videoBytes != null
                  ? 'Video: ${_videoName ?? "imechaguliwa"}'
                  : 'Chagua Video (hiari)'),
            ),
            if (_videoBytes != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() { _videoBytes = null; _videoName = null; }),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text("Ondoa video", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // ===== CATEGORY =====
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                  labelText: "Category *", border: OutlineInputBorder()),
              items: widget.categories.map((c) {
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),

            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Jina la Service", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: "Maelezo", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Bei (TSh)", border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // ===== SIKU =====
            Text("Siku za Kazi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _allDays.map((d) {
                final code = d['code']!;
                final name = d['name']!;
                final selected = _selectedDays.contains(code);
                return FilterChip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedDays.add(code);
                    } else {
                      _selectedDays.remove(code);
                    }
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ===== MUDA =====
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(_startTime == null ? 'Anza' : _startTime!.format(context)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.access_time_filled),
                    label: Text(_endTime == null ? 'Isha' : _endTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: _fixedPrice,
              onChanged: (v) => setState(() => _fixedPrice = v),
              title: const Text("Bei Isiyobadilika (Fixed)"),
              subtitle: const Text("Kwa AI Diagnosis (30,000)"),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Hifadhi Mabadiliko" : "Ongeza Service"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
