import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/rider/pickup_confirmation_screen.dart';
import 'package:deliver4me_mobile/services/order_service.dart';

class PickupVerificationScreen extends StatefulWidget {
  final OrderModel order;
  const PickupVerificationScreen({super.key, required this.order});

  @override
  State<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState extends State<PickupVerificationScreen> {
  final _codeController = TextEditingController();
  final _orderService = OrderService();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter pickup code')));
      return;
    }

    // In a real app, the Pickup Code might be different from Delivery Code or the same.
    // For simplicity, we assume the sender provides the 'deliveryCode' or we match via API.
    // Here we just check against a mock or proceed if API handles it.
    // Assuming backend verification or simple matching if we had the code locally (security risk if local).
    // Let's call API to verify pickup.

    setState(() => _isLoading = true);

    try {
      // Simulate verification or call real API
      if (widget.order.deliveryCode == code) {
        // Update Status to PickedUp
        await _orderService.updateOrderStatus(
            widget.order.id, OrderStatus.pickedUp);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => PickupConfirmationScreen(order: widget.order)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Invalid Code'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Pickup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 80, color: Color(0xFF135BEC)),
            const SizedBox(height: 24),
            const Text(
              'Enter Pickup Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask the sender for the 4-digit code to confirm you have received the parcel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '0000',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Pickup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
