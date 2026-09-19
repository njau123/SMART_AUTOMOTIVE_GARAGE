import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// NewsTicker — inaonyesha picha + maandishi yanatembea
/// (kutoka kulia → kushoto), kama TV news ticker.
class NewsTicker extends StatefulWidget {
  /// Kila item: { "image": "url", "title": "...", "description": "..." }
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  const NewsTicker({
    super.key,
    required this.items,
    this.icon = Icons.campaign_outlined,
    this.backgroundColor,
    this.textColor,
    this.height = 64,
  });

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _controller.addListener(_scroll);
  }

  void _scroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final current = _scrollController.offset;
    final newOffset = current + 0.6;
    if (newOffset >= maxScroll) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.jumpTo(newOffset);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final bg = widget.backgroundColor ?? AppColors.primary;
    final fg = widget.textColor ?? Colors.white;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.85)],
        ),
      ),
      child: Row(
        children: [
          // Icon ya kushoto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: Icon(widget.icon, color: fg, size: 20),
          ),
          // Ticker (picha + maandishi)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (_, i) => _item(widget.items[i], fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(Map<String, dynamic> item, Color fg) {
    final imageUrl = (item['image'] ?? '').toString();
    final title = (item['title'] ?? '').toString();
    final description = (item['description'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Picha
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image_outlined, color: fg, size: 22),
                ),
              ),
            ),
          const SizedBox(width: 10),
          // Maandishi
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (description.isNotEmpty)
                SizedBox(
                  width: 220,
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: fg.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
