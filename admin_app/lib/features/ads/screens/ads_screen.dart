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
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _targetUrl = TextEditingController();

  String _adType = 'BANNER';

  // Bytes (inafanya kazi Web + Mobile)
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _videoBytes;
  String? _videoName;

  bool _submitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _targetUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = x.name;
        });
      }
    } catch (e) {
      if (mounted) _snack('Imeshindwa kuchagua picha: $e', error: true);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true, // ← muhimu kwa Web
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _videoBytes = result.files.single.bytes;
          _videoName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) _snack('Imeshindwa kuchagua video: $e', error: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await AdminAPI.createAdvertisement(
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageBytes: _imageBytes,
        videoBytes: _videoBytes,
        imageName: _imageName,
        videoName: _videoName,
        adType: _adType,
      );

      if (!mounted) return;
      _snack('Advertisement created successfully!');
      setState(() {
        _title.clear();
        _description.clear();
        _targetUrl.clear();
        _imageBytes = null;
        _imageName = null;
        _videoBytes = null;
        _videoName = null;
        _adType = 'BANNER';
      });
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Advertisements')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image preview + picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: 180,
                                height: 180,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_outlined,
                                    size: 50, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text('Chagua Picha',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.primary)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Title ni lazima' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Maelezo / Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Maelezo ni lazima' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _targetUrl,
                  decoration: const InputDecoration(
                    labelText: 'Target URL (hiari)',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _adType,
                  decoration: const InputDecoration(
                    labelText: 'Aina ya Tangazo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BANNER', child: Text('Banner')),
                    DropdownMenuItem(value: 'CARD', child: Text('Card')),
                    DropdownMenuItem(value: 'POPUP', child: Text('Popup')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                  ],
                  onChanged: (v) => setState(() => _adType = v ?? 'BANNER'),
                ),
                const SizedBox(height: 14),

                // Video picker (optional)
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: Text(_videoBytes != null
                      ? 'Video: ${_videoName ?? "imechaguliwa"}'
                      : 'Chagua Video (hiari)'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.upload),
                    label: Text(_submitting
                        ? 'Inatuma...'
                        : 'Publish Advertisement'),
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
