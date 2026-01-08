import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/rider/pickup_verification_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ArrivalAtPickupScreen extends StatelessWidget {
  final OrderModel order;

  const ArrivalAtPickupScreen({super.key, required this.order});

  Future<void> _openMap() async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${order.pickup.latitude},${order.pickup.longitude}';
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go to Pickup'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter:
                  LatLng(order.pickup.latitude, order.pickup.longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.deliver4me.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point:
                        LatLng(order.pickup.latitude, order.pickup.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.store,
                        color: Color(0xFF135BEC), size: 40),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black26)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pickup Location',
                          style: TextStyle(color: Colors.grey)),
                      IconButton(
                          onPressed: _openMap,
                          icon:
                              const Icon(Icons.map, color: Color(0xFF135BEC))),
                    ],
                  ),
                  Text(
                    order.pickup.address,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text("Sender: ${order.senderId}",
                          style: const TextStyle(
                              color: Colors
                                  .white)), // Usually get name from ID fetch
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Verification
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PickupVerificationScreen(order: order)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('I Have Arrived'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
