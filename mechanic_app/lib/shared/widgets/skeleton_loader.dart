import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final int listItemCount;
  const SkeletonLoader({super.key, this.listItemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: listItemCount,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        height: 100,
      ),
    );
  }
}
