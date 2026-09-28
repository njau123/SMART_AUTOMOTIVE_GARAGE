import 'package:flutter/material.dart';
import '../../../shared/widgets/smart_video_player.dart';
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
            Stack(
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
                // Video badge kama news ina video
                if (_hasVideo(n))
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 16),
                    ),
                  ),
              ],
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
    final image = (n['featured_image'] ?? '').toString();
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
              // VIDEO (kama ipo)
              if (_hasVideo(n)) ...[
                const SizedBox(height: 16),
                SmartVideoPlayer(
                  url: _getVideoUrl(n) ?? '',
                  height: 220,
                  autoPlay: false,
                ),
              ],
              // FEATURED IMAGE (kama ipo na hakuna video)
              if (!_hasVideo(n) && image.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    image.startsWith('http') ? image : 'http://10.0.2.2:8000$image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
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

  bool _hasVideo(Map<String, dynamic> n) {
    final videoUrl = (n['video_url'] ?? '').toString();
    final videoFile = (n['video_file'] ?? '').toString();
    final videos = n['videos'];
    return videoUrl.isNotEmpty ||
        videoFile.isNotEmpty ||
        (videos is List && videos.isNotEmpty);
  }

  String? _getVideoUrl(Map<String, dynamic> n) {
    final videoUrl = (n['video_url'] ?? '').toString();
    if (videoUrl.isNotEmpty) return videoUrl;

    final videoFile = (n['video_file'] ?? '').toString();
    if (videoFile.isNotEmpty) {
      return videoFile.startsWith('http')
          ? videoFile
          : 'https://smart-garage-backend.onrender.com$videoFile';
    }

    final videos = n['videos'];
    if (videos is List && videos.isNotEmpty) {
      final v = videos.first.toString();
      return v.startsWith('http')
          ? v
          : 'https://smart-garage-backend.onrender.com$v';
    }
    return null;
  }
}
