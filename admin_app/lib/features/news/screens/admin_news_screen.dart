
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title na content ni lazima"), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final res = await AdminAPI.createNews(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        videoUrl: _videoUrlCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("News imetumwa na users wote wamepata notification!"),
              backgroundColor: Colors.green),
        );
        _titleCtrl.clear();
        _contentCtrl.clear();
        _videoUrlCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? "Error"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Post News')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: "Title ya habari",
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                    labelText: "Content / Maelezo",
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _videoUrlCtrl,
                decoration: const InputDecoration(
                    labelText: "Video URL (optional)",
                    prefixIcon: Icon(Icons.video_library),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _posting ? null : _post,
                  icon: const Icon(Icons.send),
                  label: Text(_posting ? "Inatuma..." : "Tuma News kwa Users Wote"),
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
    );
  }
}
