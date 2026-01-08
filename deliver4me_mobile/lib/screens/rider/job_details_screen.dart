import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliver4me_mobile/screens/rider/rider_active_delivery_screen.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const JobDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  final orderService = OrderService();
  bool isLoading = false;

  Future<void> _acceptJob(OrderModel order) async {
    setState(() => isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('No user logged in');
      }

      await orderService.acceptOrder(order.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiderActiveDeliveryScreen(orderId: order.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderStream = ref.watch(orderStreamProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        centerTitle: true,
      ),
      body: orderStream.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Job not found'));
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Map header
                    SizedBox(
                      height: 250,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            order.pickup.latitude,
                            order.pickup.longitude,
                          ),
                          initialZoom: 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.deliver4me.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  order.pickup.latitude,
                                  order.pickup.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.radio_button_checked,
                                  color: Color(0xFF135BEC),
                                  size: 40,
                                ),
                              ),
                              Marker(
                                point: LatLng(
                                  order.dropoff.latitude,
                                  order.dropoff.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Earnings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'You\'ll Earn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₦${order.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Route
                          const Text(
                            'Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildLocationItem(
                            Icons.radio_button_checked,
                            'Pickup',
                            order.pickup.address,
                            const Color(0xFF135BEC),
                          ),

                          const SizedBox(height: 8),

                          _buildLocationItem(
                            Icons.location_on,
                            'Drop-off',
                            order.dropoff.address,
                            Colors.red,
                          ),

                          const SizedBox(height: 24),

                          // Parcel Info
                          const Text(
                            'Parcel Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildInfoRow('Description', order.parcelDescription),
                          _buildInfoRow('Weight', order.weightCategory),
                          _buildInfoRow('Recipient', order.recipientName),
                          _buildInfoRow('Phone', order.recipientPhone),

                          if (order.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.notes,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      bottomNavigationBar: orderStream.maybeWhen(
        data: (order) {
          if (order == null || order.status != OrderStatus.pending) return null;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _acceptJob(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Accept Job'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildLocationItem(
      IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
