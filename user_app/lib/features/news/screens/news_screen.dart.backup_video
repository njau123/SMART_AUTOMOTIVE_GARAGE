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
  bool _loading = true;
  String? _error;
  List<dynamic> _news = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PublicAPI.getNews();
      if (!mounted) return;
      setState(() {
        _news = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'News',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _news.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final n = _news[i] as Map<String, dynamic>;
                      return _newsTile(n);
                    },
                  ),
      ),
    );
  }

  Widget _newsTile(Map<String, dynamic> n) {
    final title = (n['title'] ?? '').toString();
    final summary = (n['summary'] ?? n['content'] ?? '').toString();
    final image = (n['featured_image'] ?? '').toString();

    return GestureDetector(
      onTap: () => _showDetails(n),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.surfaceAlt,
                child: image.isNotEmpty
                    ? Image.network(
                        image.startsWith('http')
                            ? image
                            : 'http://10.0.2.2:8000$image',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.newspaper_outlined,
                            color: AppColors.textMuted),
                      )
                    : const Icon(Icons.newspaper_outlined,
                        color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                (n['title'] ?? '').toString(),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (n['content'] ?? n['summary'] ?? '').toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
