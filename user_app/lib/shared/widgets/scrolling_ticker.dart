import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ScrollingTicker extends StatefulWidget {
  final List<String> messages;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;

  const ScrollingTicker({
    super.key,
    required this.messages,
    this.icon = Icons.campaign_outlined,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<ScrollingTicker> createState() => _ScrollingTickerState();
}

class _ScrollingTickerState extends State<ScrollingTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _controller.addListener(_scroll);
  }

  void _scroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll <= 0) return;
    final newOffset = current + 0.5;
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
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    final bg = widget.backgroundColor ?? AppColors.primary;
    final fg = widget.textColor ?? Colors.white;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.85)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.black.withValues(alpha: 0.15),
            child: Icon(widget.icon, color: fg, size: 18),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.messages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.messages[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
