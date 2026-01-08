import 'package:flutter/material.dart';

class RiderReviewsScreen extends StatelessWidget {
  const RiderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Reviews
    final reviews = [
      {
        'user': 'John D.',
        'rating': 5.0,
        'comment': 'Fast and reliable!',
        'date': '2 days ago',
      },
      {
        'user': 'Sarah M.',
        'rating': 4.0,
        'comment': 'Good service.',
        'date': '1 week ago',
      },
      {
        'user': 'Mike T.',
        'rating': 5.0,
        'comment': 'Excellent handling of fragile items.',
        'date': '2 weeks ago',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final rating = review['rating'] as double;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review['user'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        review['date'] as String,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(review['comment'] as String),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
