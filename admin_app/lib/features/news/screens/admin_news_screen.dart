import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> _news = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getNews();
      if (mounted) setState(() { _news = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Imeshindwa kupata news: $e', error: true);
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
      builder: (_) => _NewsForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(dynamic item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Habari?"),
        content: Text("Una uhakika kufuta '${item['title']}'?"),
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
        await AdminAPI.deleteNews(item['id'] as int);
        _snack("Habari imefutwa");
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
      appBar: AppBar(title: const Text('News')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text("Ongeza"),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _news.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.newspaper_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text("Hakuna habari", style: GoogleFonts.poppins()),
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
                    itemCount: _news.length,
                    itemBuilder: (_, i) {
                      final n = _news[i];
                      final img = (n['featured_image'] ?? '').toString();
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
                                      child: const Icon(Icons.newspaper),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.newspaper, color: AppColors.primary),
                                ),
                          title: Text(n['title']?.toString() ?? 'Untitled'),
                          subtitle: Text(
                            (n['content']?.toString() ?? '').length > 80
                                ? '${n['content'].toString().substring(0, 80)}...'
                                : n['content']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openForm(Map<String, dynamic>.from(n as Map));
                              if (v == 'delete') _delete(n);
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

class _NewsForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _NewsForm({this.existing});
  @override
  State<_NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<_NewsForm> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
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
      _contentCtrl.text = widget.existing!['content']?.toString() ?? '';
      _videoUrlCtrl.text = widget.existing!['video_url']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      _snack("Title na content ni lazima", error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await AdminAPI.createNews(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          featuredImageBytes: _imageBytes,
          videoFileBytes: _videoBytes,
          featuredImageName: _imageName,
          videoFileName: _videoName,
          videoUrl: _videoUrlCtrl.text.trim().isEmpty ? null : _videoUrlCtrl.text.trim(),
        );
      } else {
        await AdminAPI.updateNews(
          id: widget.existing!['id'] as int,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? "Hariri Habari" : "Ongeza Habari Mpya",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _contentCtrl, maxLines: 5,
                decoration: const InputDecoration(labelText: "Content", border: OutlineInputBorder())),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              TextField(controller: _videoUrlCtrl,
                  decoration: const InputDecoration(labelText: "Video URL (optional)", border: OutlineInputBorder())),
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
                    : Text(isEdit ? "Hifadhi" : "Tuma"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
