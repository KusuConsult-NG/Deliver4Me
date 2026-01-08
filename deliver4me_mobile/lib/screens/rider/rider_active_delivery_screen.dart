import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/services/wallet_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:deliver4me_mobile/screens/rider/delivery_confirmation_screen.dart';
import 'package:deliver4me_mobile/screens/rider/pickup_verification_screen.dart';
import 'package:deliver4me_mobile/screens/rider/arrival_screen.dart';

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
  final walletService = WalletService();
  final _deliveryCodeController = TextEditingController();
  bool isLoading = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateRiderLocation();
    });
  }

  Future<void> _updateRiderLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await orderService.updateRiderLocation(
        widget.orderId,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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

      // Add earnings to rider wallet with atomic log
      await walletService.updateBalanceWithLog(
        userId: user.uid,
        amount: order.price,
        description: 'Delivery earnings: ${order.parcelDescription}',
        type: 'earning',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery complete! ₦${order.price} added to wallet'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryConfirmationScreen(order: order),
          ),
        );
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

  // Mark arrival at pickup location
  Future<void> _markArrivedAtPickup(OrderModel order) async {
    if (order.arrivedAtPickupTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already marked as arrived at pickup'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await orderService.markArrivedAtPickup(widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Arrival at pickup marked! Waiting timer started.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Mark arrival at dropoff location
  Future<void> _markArrivedAtDropoff(OrderModel order) async {
    if (order.arrivedAtDropoffTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already marked as arrived at dropoff'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await orderService.markArrivedAtDropoff(widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('✓ Arrival at dropoff marked! Waiting timer started.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

          // Check for Arrival State
          if (order.status == OrderStatus.accepted &&
              order.arrivedAtPickupTime != null) {
            return ArrivalScreen(
              order: order,
              isPickup: true,
              onComplete: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupVerificationScreen(order: order),
                  ),
                );
              },
            );
          }

          if (order.status == OrderStatus.inTransit &&
              order.arrivedAtDropoffTime != null) {
            return ArrivalScreen(
              order: order,
              isPickup: false,
              onComplete: () => _completeDelivery(order),
            );
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

                          // Delivery code input (only when in transit)
                          if (order.status == OrderStatus.inTransit) ...[
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT INSTRUCTION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          Icon(icon, color: const Color(0xFF135BEC)),
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
      // Show "Arrived at Pickup" if not yet marked
      if (order.arrivedAtPickupTime == null) {
        return ElevatedButton.icon(
          onPressed: isLoading ? null : () => _markArrivedAtPickup(order),
          icon: const Icon(Icons.location_on),
          label: const Text('📍 Arrived at Pickup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      }
      // Already arrived, show pickup confirmation
      return ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                // Navigate to PickupVerificationScreen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupVerificationScreen(order: order),
                  ),
                );
                // On return, stream will update UI if status changed
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135BEC),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Verify & Confirm Pickup'),
      );
    } else if (order.status == OrderStatus.pickedUp) {
      return ElevatedButton(
        onPressed: isLoading
            ? null
            : () => _updateStatus(order, OrderStatus.inTransit),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Start Transit'),
      );
    } else if (order.status == OrderStatus.inTransit) {
      // Show "Arrived at Dropoff" if not yet marked
      if (order.arrivedAtDropoffTime == null) {
        return ElevatedButton.icon(
          onPressed: isLoading ? null : () => _markArrivedAtDropoff(order),
          icon: const Icon(Icons.location_on),
          label: const Text('📍 Arrived at Dropoff'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      }
      // Already arrived, show complete delivery
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
