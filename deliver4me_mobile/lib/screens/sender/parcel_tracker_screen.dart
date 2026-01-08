import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliver4me_mobile/screens/sender/edit_delivery_screen.dart';
import 'package:deliver4me_mobile/screens/common/chat_screen.dart';

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

    return orderStream.when(
      data: (order) {
        if (order == null) {
          return const Scaffold(body: Center(child: Text('Order not found')));
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Track Parcel'),
            centerTitle: true,
            actions: [
              if (order.status == OrderStatus.pending)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDeliveryScreen(order: order),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: _buildTrackingView(context, order),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading order: $error')),
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
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Finding Rider...';
        break;
      case OrderStatus.accepted:
        statusColor = const Color(0xFF135BEC);
        statusText = 'Rider Assigned';
        break;
      case OrderStatus.pickedUp:
        statusColor = Colors.green;
        statusText = 'In Transit';
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusText = 'Delivered';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status.toString().split('.').last.toUpperCase();
    }

    // Calculate metrics
    double distanceCovered = 0.0;
    double distanceRemaining = 0.0;
    int timeRemainingMinutes = 0;

    // Average speed assumption: 30 km/h (0.5 km/min) for city traffic
    const double avgSpeedKmPerMin = 0.5;

    if (order.riderLocation != null && order.status == OrderStatus.inTransit) {
      final riderLat = order.riderLocation!['latitude'] as double;
      final riderLng = order.riderLocation!['longitude'] as double;

      // Covered: Pickup -> Rider (Current Location)
      distanceCovered = const Distance().as(
          LengthUnit.Kilometer,
          LatLng(order.pickup.latitude, order.pickup.longitude),
          LatLng(riderLat, riderLng));

      // Remaining: Rider -> Dropoff
      distanceRemaining = const Distance().as(
          LengthUnit.Kilometer,
          LatLng(riderLat, riderLng),
          LatLng(order.dropoff.latitude, order.dropoff.longitude));

      timeRemainingMinutes = (distanceRemaining / avgSpeedKmPerMin).round();
    } else if (order.riderLocation != null &&
        order.status == OrderStatus.accepted) {
      // Rider -> Pickup (Remaining to pickup)
      final riderLat = order.riderLocation!['latitude'] as double;
      final riderLng = order.riderLocation!['longitude'] as double;

      distanceRemaining = const Distance().as(
          LengthUnit.Kilometer,
          LatLng(riderLat, riderLng),
          LatLng(order.pickup.latitude, order.pickup.longitude));

      timeRemainingMinutes = (distanceRemaining / avgSpeedKmPerMin).round();
    }

    // Ensure strictly positive
    if (timeRemainingMinutes < 1) timeRemainingMinutes = 1;

    return Column(
      children: [
        Container(
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
        ),
        if (order.status == OrderStatus.inTransit ||
            order.status == OrderStatus.accepted)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                    'Covered', '${distanceCovered.toStringAsFixed(1)} km'),
                _buildMetric('Distance Left',
                    '${distanceRemaining.toStringAsFixed(1)} km'),
                _buildMetric('Time Left', '$timeRemainingMinutes min',
                    isHighlight: true),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isHighlight ? const Color(0xFF135BEC) : Colors.black)),
      ],
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
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF135BEC),
                        child: Icon(Icons.person, color: Colors.white),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Call feature mock')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                orderId: order.id,
                                otherUserName: order.riderName ?? 'Rider',
                                otherUserId: order.riderId!,
                              ),
                            ),
                          );
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

                ...order.timeline.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final isLast = index == order.timeline.length - 1;

                  return _buildTimelineItem(
                    event.title,
                    _formatTime(event.timestamp),
                    event.isComplete,
                    isLast: isLast,
                  );
                }),

                const SizedBox(height: 16),

                // Delivery code (if in transit)
                if (order.status == OrderStatus.pickedUp ||
                    order.status == OrderStatus.accepted)
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
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
