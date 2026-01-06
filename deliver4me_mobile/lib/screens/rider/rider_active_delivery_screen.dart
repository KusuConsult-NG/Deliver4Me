import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiderActiveDeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;

  const RiderActiveDeliveryScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<RiderActiveDeliveryScreen> createState() =>
      _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState
    extends ConsumerState<RiderActiveDeliveryScreen> {
  final orderService = OrderService();
  final userService = UserService();
  final _deliveryCodeController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _deliveryCodeController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() => isLoading = true);

    try {
      await orderService.updateOrderStatus(widget.orderId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _completeDelivery(OrderModel order) async {
    // Verify delivery code
    if (_deliveryCodeController.text.trim() != order.deliveryCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid delivery code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user == null) throw Exception('No user logged in');

      // Update order status to delivered
      await orderService.updateOrderStatus(
          widget.orderId, OrderStatus.delivered);

      // Add earnings to rider wallet
      await userService.updateWalletBalance(user.uid, order.price);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Delivery complete! \$${order.price} added to wallet'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to jobs
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing delivery: $e'),
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
        title: const Text('Active Delivery'),
        centerTitle: true,
      ),
      body: orderStream.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Map
                  Expanded(
                    flex: 2,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          order.pickup.latitude,
                          order.pickup.longitude,
                        ),
                        initialZoom: 13.0,
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status
                          _buildStatusBanner(order.status),

                          const SizedBox(height: 16),

                          // Customer info
                          _buildInfoCard(
                            'Customer',
                            order.recipientName,
                            order.recipientPhone,
                            Icons.person,
                          ),

                          const SizedBox(height: 12),

                          // Dropoff address
                          _buildInfoCard(
                            'Drop-off Location',
                            order.dropoff.address,
                            null,
                            Icons.location_on,
                          ),

                          const SizedBox(height: 12),

                          // Parcel info
                          _buildInfoCard(
                            'Parcel',
                            order.parcelDescription,
                            order.weightCategory,
                            Icons.inventory,
                          ),

                          const SizedBox(height: 16),

                          // Delivery code input (only when picked up)
                          if (order.status == 'picked_up') ...[
                            const Text(
                              'Enter Delivery Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _deliveryCodeController,
                              decoration: const InputDecoration(
                                hintText: 'Enter 4-digit code',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                            ),
                          ],

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
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
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: orderStream.maybeWhen(
        data: (order) {
          if (order == null) return null;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButton(order),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildStatusBanner(OrderStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case OrderStatus.accepted:
        color = const Color(0xFF135BEC);
        text = 'Head to Pickup Location';
        icon = Icons.directions;
        break;
      case OrderStatus.pickedUp:
        color = Colors.orange;
        text = 'Deliver to Customer';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivery Complete!';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = status.toString().split('.').last;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, String? subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF135BEC)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(OrderModel order) {
    if (order.status == OrderStatus.accepted) {
      return ElevatedButton(
        onPressed:
            isLoading ? null : () => _updateStatus(order, OrderStatus.pickedUp),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135BEC),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Mark as Picked Up'),
      );
    } else if (order.status == OrderStatus.pickedUp) {
      return ElevatedButton(
        onPressed: isLoading ? null : () => _completeDelivery(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Complete Delivery'),
      );
    } else if (order.status == OrderStatus.delivered) {
      return ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Back to Jobs'),
      );
    }

    return const SizedBox.shrink();
  }
}
