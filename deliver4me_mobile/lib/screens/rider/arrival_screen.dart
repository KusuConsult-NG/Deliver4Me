import 'dart:async';
import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/common/chat_screen.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ArrivalScreen extends StatefulWidget {
  final OrderModel order;
  final bool isPickup;
  final VoidCallback
      onComplete; // Callback to proceed to next step (Verify or Complete)

  const ArrivalScreen({
    super.key,
    required this.order,
    required this.isPickup,
    required this.onComplete,
  });

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen> {
  late Timer _timer;
  Duration _waitingDuration = Duration.zero;
  final _userService = UserService();
  String? _senderName;
  String? _senderPhone;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    if (widget.isPickup) {
      _fetchSenderDetails();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateDuration();
    });
  }

  Future<void> _fetchSenderDetails() async {
    try {
      final user = await _userService.getUserById(widget.order.senderId);
      if (user != null && mounted) {
        setState(() {
          _senderName = user.name;
          _senderPhone = user.phone;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sender details: $e');
    }
  }

  void _calculateDuration() {
    final arrivalTime = widget.isPickup
        ? widget.order.arrivedAtPickupTime
        : widget.order.arrivedAtDropoffTime;

    if (arrivalTime != null) {
      if (mounted) {
        setState(() {
          _waitingDuration = DateTime.now().difference(arrivalTime);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactName = widget.isPickup
        ? (_senderName ?? 'Sender')
        : widget.order.recipientName;
    final contactPhone =
        widget.isPickup ? (_senderPhone ?? '') : widget.order.recipientPhone;

    return Scaffold(
      backgroundColor: const Color(0xFF135BEC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Success Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'YOU HAVE ARRIVED!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isPickup ? 'At Pickup Location' : 'At Drop-off Location',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Timer Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'WAITING TIME',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(_waitingDuration),
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Contact Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactButton(
                        icon: Icons.phone,
                        label: 'Call',
                        onTap: () => _makePhoneCall(contactPhone),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildContactButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                orderId: widget.order.id,
                                otherUserName: contactName,
                                otherUserId: widget.isPickup
                                    ? widget.order.senderId
                                    : 'recipient',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Proceed Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isPickup ? 'VERIFY PICKUP' : 'COMPLETE DELIVERY',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[800], size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
