import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
// import 'package:deliver4me_mobile/screens/rider/arrival_at_pickup_screen.dart';
import 'package:deliver4me_mobile/screens/rider/rider_active_delivery_screen.dart';

class NewJobOfferScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const NewJobOfferScreen({super.key, required this.order});

  @override
  ConsumerState<NewJobOfferScreen> createState() => _NewJobOfferScreenState();
}

class _NewJobOfferScreenState extends ConsumerState<NewJobOfferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  final _orderService = OrderService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 45));
    _timerController.forward();
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Auto-reject or verify existence
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _acceptJob() async {
    setState(() => _isLoading = true);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await _orderService.acceptOrder(widget.order.id, user.uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  RiderActiveDeliveryScreen(orderId: widget.order.id)),
        );
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
      backgroundColor: Colors.black, // Dark background for contrast
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar
            LinearProgressIndicator(
              value: _timerController.value,
              backgroundColor: Colors.grey[800],
              color: Colors.orange,
              minHeight: 8,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('NEW JOB OFFER',
                        style: TextStyle(
                            color: Colors.orange,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    const Text('EARNINGS',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      '₦${widget.order.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoRow(Icons.radio_button_checked, 'Pick Up',
                        widget.order.pickup.address),
                    const SizedBox(height: 24),
                    _buildInfoRow(Icons.location_on, 'Drop Off',
                        widget.order.dropoff.address),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Distance', '4.2 km'), // Real data needed
                        _buildStat('Parcel', widget.order.parcelDescription),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(20),
                              foregroundColor: Colors.red),
                          child: const Text('DECLINE'),
                        )),
                        const SizedBox(width: 16),
                        Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _acceptJob,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color(0xFF135BEC),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('ACCEPT JOB',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }
}
