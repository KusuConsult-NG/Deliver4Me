import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliver4me_mobile/shared/location_service.dart';
import 'package:deliver4me_mobile/widgets/map_widget.dart';
import 'dart:async';

class ParcelTrackerScreen extends StatefulWidget {
  const ParcelTrackerScreen({super.key});

  @override
  State<ParcelTrackerScreen> createState() => _ParcelTrackerScreenState();
}

class _ParcelTrackerScreenState extends State<ParcelTrackerScreen> {
  final LatLng _pickupLocation = const LatLng(40.7128, -74.0060);
  final LatLng _dropoffLocation = const LatLng(40.7489, -73.9680);
  LatLng _riderLocation = const LatLng(40.7308, -73.9973);
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startTracking() {
    // Simulate rider movement for demo
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _riderLocation = LatLng(
            _riderLocation.latitude + 0.001,
            _riderLocation.longitude + 0.001,
          );
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = [_pickupLocation, _riderLocation, _dropoffLocation];

    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101622),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Track Delivery'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Area with Real Tracking
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MapWidget(
                  center: _riderLocation,
                  zoom: 14,
                  markers: [
                    // Pickup marker
                    MapWidget.buildMarker(
                      point: _pickupLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.radio_button_checked,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Rider marker (moving)
                    MapWidget.buildMarker(
                      point: _riderLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Dropoff marker
                    MapWidget.buildMarker(
                      point: _dropoffLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF92A4C9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                  polylines: [
                    MapWidget.buildPolyline(
                      points: routePoints,
                      color: const Color(0xFF135BEC),
                      strokeWidth: 3,
                    ),
                  ],
                ),

                // Rider info card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF192233).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF324467),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 2,
                            ),
                            color: Colors.grey[700],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Marcus Johnson',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.verified,
                                    color: Color(0xFF135BEC),
                                    size: 16,
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.9 • 350 deliveries',
                                    style: TextStyle(
                                      color: Color(0xFF92A4C9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF135BEC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF324467),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Live ETA Badge
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'LIVE ETA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '12 min',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section (same as before)
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF192233),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF324467),
                  ),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF324467),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.two_wheeler,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'In Transit',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timeline
                  _buildTimelineItem(
                    Icons.check_circle,
                    'Package Picked Up',
                    '123 Main St, Downtown',
                    '2:15 PM',
                    true,
                  ),
                  _buildTimelineItem(
                    Icons.radio_button_checked,
                    'In Transit',
                    'On the way to destination',
                    '2:30 PM',
                    true,
                  ),
                  _buildTimelineItem(
                    Icons.location_on,
                    'Out for Delivery',
                    '450 Highland Ave',
                    'Pending',
                    false,
                  ),

                  const SizedBox(height: 24),

                  // Delivery Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2536),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF324467).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELIVERY CODE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            '2847',
                            style: TextStyle(
                              color: Color(0xFF135BEC),
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Share this code with your rider',
                            style: TextStyle(
                              color: Color(0xFF92A4C9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTimelineItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    bool isComplete,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFF135BEC)
                      : const Color(0xFF324467),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              if (subtitle != 'On the way to destination' &&
                  subtitle != '450 Highland Ave')
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isComplete
                      ? const Color(0xFF135BEC).withValues(alpha: 0.5)
                      : const Color(0xFF324467),
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
                    color: isComplete ? Colors.white : const Color(0xFF92A4C9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF92A4C9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF92A4C9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
