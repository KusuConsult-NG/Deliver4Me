import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/screens/sender/parcel_tracker_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double amount;
  final String paymentMethod;

  const PaymentConfirmationScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text('Payment Successful'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Your order has been confirmed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 40),

            // Payment Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Order ID', orderId.substring(0, 8)),
                  const Divider(height: 24),
                  _buildDetailRow(
                      'Amount Paid', '₦${amount.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildDetailRow('Payment Method', paymentMethod),
                  const Divider(height: 24),
                  _buildDetailRow('Status', 'Confirmed',
                      valueColor: Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Track Order Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ParcelTrackerScreen(orderId: orderId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Track Your Order'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Return Home Button
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
