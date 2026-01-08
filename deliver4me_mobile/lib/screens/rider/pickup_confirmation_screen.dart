import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/rider/rider_active_delivery_screen.dart';

class PickupConfirmationScreen extends StatelessWidget {
  final OrderModel order;
  const PickupConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF135BEC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Pickup Confirmed!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'You have successfully verified the parcel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              const Text(
                'Next: Start heading to the drop-off location.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiderActiveDeliveryScreen(orderId: order.id),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text('Start Transit',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
