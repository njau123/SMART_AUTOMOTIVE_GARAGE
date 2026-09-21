import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});
  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  List<dynamic> _ads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getAds();
      if (mounted) setState(() { _ads = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Imeshindwa kupata ads: $e', error: true);
      }
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AdForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(dynamic ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Tangazo?"),
        content: Text("Una uhakika kufuta '${ad['title']}'?"),
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
        await AdminAPI.deleteAd(ad['id'] as int);
        _snack("Tangazo limefutwa");
        _load();
      } catch (e) {
        _snack(e.toString().replaceAll("Exception: ", ""), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Advertisements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text("Ongeza"),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text("Hakuna matangazo", style: GoogleFonts.poppins()),
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
                    itemCount: _ads.length,
                    itemBuilder: (_, i) {
                      final a = _ads[i];
                      final img = (a['image'] ?? '').toString();
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
                                      child: const Icon(Icons.campaign),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.campaign, color: AppColors.primary),
                                ),
                          title: Text(a['title']?.toString() ?? 'Untitled'),
                          subtitle: Text(
                            a['description']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openForm(Map<String, dynamic>.from(a as Map));
                              if (v == 'delete') _delete(a);
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

class _AdForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _AdForm({this.existing});
  @override
  State<_AdForm> createState() => _AdFormState();
}

class _AdFormState extends State<_AdForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _targetUrlCtrl = TextEditingController();
  String _adType = 'BANNER';
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _videoBytes;
  String? _videoName;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title']?.toString() ?? '';
      _descriptionCtrl.text = widget.existing!['description']?.toString() ?? '';
      _targetUrlCtrl.text = widget.existing!['target_url']?.toString() ?? '';
      _adType = widget.existing!['advertisement_type']?.toString() ?? 'BANNER';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _targetUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() { _imageBytes = bytes; _imageName = x.name; });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video, withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _videoBytes = result.files.single.bytes;
        _videoName = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await AdminAPI.createAdvertisement(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          imageBytes: _imageBytes,
          videoBytes: _videoBytes,
          imageName: _imageName,
          videoName: _videoName,
          adType: _adType,
        );
      } else {
        await AdminAPI.updateAd(
          id: widget.existing!['id'] as int,
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? "Hariri Tangazo" : "Ongeza Tangazo",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Title ni lazima" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Maelezo", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Maelezo ni lazima" : null,
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetUrlCtrl,
                  decoration: const InputDecoration(labelText: "Target URL (hiari)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _adType,
                  decoration: const InputDecoration(labelText: "Aina", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'BANNER', child: Text('Banner')),
                    DropdownMenuItem(value: 'CARD', child: Text('Card')),
                    DropdownMenuItem(value: 'POPUP', child: Text('Popup')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                  ],
                  onChanged: (v) => setState(() => _adType = v ?? 'BANNER'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_imageBytes == null ? "Chagua Picha" : "Badilisha Picha"),
                ),
                if (_imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: Text(_videoBytes == null ? "Chagua Video (hiari)" : "Video: ${_videoName ?? ''}"),
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
                      : Text(isEdit ? "Hifadhi" : "Publish"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
