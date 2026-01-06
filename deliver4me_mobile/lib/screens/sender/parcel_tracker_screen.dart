import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ParcelTrackerScreen extends ConsumerWidget {
  final String orderId;

  const ParcelTrackerScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream the order in real-time
    final orderStream = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Track Parcel'),
        centerTitle: true,
      ),
      body: orderStream.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return _buildTrackingView(context, order);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading order: $error'),
        ),
      ),
    );
  }

  Widget _buildTrackingView(BuildContext context, OrderModel order) {
    return Stack(
      children: [
        // Map View
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              order.pickup.latitude,
              order.pickup.longitude,
            ),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.deliver4me.app',
            ),
            MarkerLayer(
              markers: [
                // Pickup marker
                Marker(
                  point: LatLng(order.pickup.latitude, order.pickup.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFF135BEC),
                    size: 40,
                  ),
                ),
                // Dropoff marker
                Marker(
                  point:
                      LatLng(order.dropoff.latitude, order.dropoff.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                // Rider marker (if assigned)
                if (order.riderId != null && order.riderLocation != null)
                  Marker(
                    point: LatLng(
                      order.riderLocation!['latitude'],
                      order.riderLocation!['longitude'],
                    ),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.motorcycle,
                        color: Color(0xFF135BEC),
                        size: 30,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Status overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildStatusCard(order),
        ),

        // Bottom sheet
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomSheet(context, order),
        ),
      ],
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    Color statusColor;
    String statusText;

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Finding Rider...';
        break;
      case 'accepted':
        statusColor = Color(0xFF135BEC);
        statusText = 'Rider Assigned';
        break;
      case 'picked_up':
        statusColor = Colors.green;
        statusText = 'In Transit';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'Delivered';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (order.estimatedArrival != null)
            Text(
              'ETA: ${_formatTime(order.estimatedArrival!)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider info (if assigned)
                if (order.riderId != null) ...[
                  const Text(
                    'Your Rider',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF135BEC),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.riderName ?? 'Rider',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              order.riderPhone ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          // Call rider
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                ],

                // Timeline
                const Text(
                  'Delivery Timeline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTimelineItem(
                  'Order Confirmed',
                  _formatTime(order.createdAt),
                  true,
                ),
                if (order.acceptedAt != null)
                  _buildTimelineItem(
                    'Rider Assigned',
                    _formatTime(order.acceptedAt!),
                    true,
                  ),
                if (order.pickedUpAt != null)
                  _buildTimelineItem(
                    'Package Picked Up',
                    _formatTime(order.pickedUpAt!),
                    true,
                  ),
                _buildTimelineItem(
                  'Delivered',
                  order.deliveredAt != null
                      ? _formatTime(order.deliveredAt!)
                      : 'Pending',
                  order.deliveredAt != null,
                  isLast: true,
                ),

                const SizedBox(height: 16),

                // Delivery code (if in transit)
                if (order.status == 'picked_up' || order.status == 'accepted')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Delivery Code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.deliveryCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Share this code with the rider',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted,
      {bool isLast = false}) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[700],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? Colors.green : Colors.grey[700],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? Colors.white : Colors.grey,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
