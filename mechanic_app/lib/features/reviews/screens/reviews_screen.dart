import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final data = await ReviewsAPI.getReviews();
      setState(() => _reviews = data);
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: _reviews.isEmpty
          ? const Center(child: Text('No reviews yet'))
          : ListView.builder(
              itemCount: _reviews.length,
              itemBuilder: (ctx, i) {
                final review = _reviews[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text('${review['rating']} / 5'),
                    subtitle: Text(review['comment'] ?? ''),
                    trailing: Text(review['reviewer'] ?? 'Anonymous'),
                  ),
                );
              },
            ),
    );
  }
}
