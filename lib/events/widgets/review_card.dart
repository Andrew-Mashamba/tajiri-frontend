import 'package:flutter/material.dart';
import '../models/event_review.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class ReviewCard extends StatelessWidget {
  final EventReview review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: review.user?.avatarUrl != null ? NetworkImage(review.user!.avatarUrl!) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(review.user?.fullName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary))),
              ...List.generate(5, (i) => Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16,
                color: i < review.rating ? Colors.amber : Colors.grey.shade300,
              )),
            ],
          ),
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.content!, style: const TextStyle(fontSize: 13, color: _kPrimary, height: 1.5)),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(review.photoUrls[i], width: 60, height: 60, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
