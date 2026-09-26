import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';

/// Preview + crop ya picha kabla ya kutuma.
class ImagePreviewScreen extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const ImagePreviewScreen({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late Uint8List _currentBytes;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.bytes;
  }

  Future<void> _crop() async {
    setState(() => _cropping = true);
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      tempFile = File(
          '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(_currentBytes);

      if (!mounted) return;
      final cropped = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        compressQuality: 75,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Chakata Picha',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Chakata Picha',
            doneButtonTitle: 'Tumia',
            cancelButtonTitle: 'Ghairi',
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 500, height: 500),
          ),
        ],
      );

      if (cropped != null) {
        final newBytes = await File(cropped.path).readAsBytes();
        if (mounted) setState(() => _currentBytes = newBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crop imeshindwa: $e')),
        );
      }
    } finally {
      try { if (tempFile != null) await tempFile.delete(); } catch (_) {}
      if (mounted) setState(() => _cropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Angalia Picha',
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop, color: Colors.white),
            tooltip: 'Chakata',
            onPressed: _cropping ? null : _crop,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _cropping
                  ? const CircularProgressIndicator(color: Colors.white)
                  : InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.memory(_currentBytes, fit: BoxFit.contain),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.black87,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cropping
                          ? null
                          : () => Navigator.pop(context, null),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text('Ghairi',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _cropping
                          ? null
                          : () => Navigator.pop(context, _currentBytes),
                      icon: const Icon(Icons.send),
                      label: Text('Tuma',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
