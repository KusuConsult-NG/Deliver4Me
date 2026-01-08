import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  final String ratedUserId;
  final String ratedUserName;

  const RatingScreen({
    super.key,
    required this.orderId,
    required this.ratedUserId,
    required this.ratedUserName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userService = UserService();
      await userService.rateUser(
        widget.ratedUserId,
        _rating,
        _commentController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error submitting rating: $e'),
              backgroundColor: Colors.red),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Experience')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF135BEC).withValues(alpha: 0.1),
              child: Text(
                widget.ratedUserName.isNotEmpty
                    ? widget.ratedUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF135BEC)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your delivery with ${widget.ratedUserName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Leave a comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Rating',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
