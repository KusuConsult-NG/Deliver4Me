import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:deliver4me_mobile/shared/location_service.dart';
import 'package:deliver4me_mobile/widgets/map_widget.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationSelectionScreen extends StatefulWidget {
  const GeolocationSelectionScreen({super.key});

  @override
  State<GeolocationSelectionScreen> createState() =>
      _GeolocationSelectionScreenState();
}

class _GeolocationSelectionScreenState
    extends State<GeolocationSelectionScreen> {
  LatLng _currentCenter = const LatLng(40.7128, -74.0060); // Default: New York
  bool _isLoading = true;
  String _selectedAddress = '123 Main Street, New York, NY 10001';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      body: Stack(
        children: [
          // Map
          if (!_isLoading)
            MapWidget(
              center: _currentCenter,
              zoom: 16,
              markers: [
                MapWidget.buildMarker(
                  point: _currentCenter,
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF135BEC),
                    size: 48,
                  ),
                ),
              ],
            )
          else
            Container(
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF135BEC),
                ),
              ),
            ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF101622).withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 256,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF101622).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Search Card
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF192233),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF324467).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildLocationInput(
                          'PICK-UP',
                          'Current Location',
                          Icons.radio_button_checked,
                          true,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 27),
                          width: 2,
                          height: 16,
                          color: const Color(0xFF324467),
                        ),
                        _buildLocationInput(
                          'DROP-OFF',
                          'Enter destination',
                          Icons.check_box_outline_blank,
                          false,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Center Pin Label
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Pick-up Here',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // My Location FAB
                Padding(
                  padding: const EdgeInsets.only(right: 20.0, bottom: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: _loadCurrentLocation,
                      backgroundColor: const Color(0xFF192233),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF135BEC),
                      ),
                    ),
                  ),
                ),

                // Bottom Sheet
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF192233),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFF324467),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF324467),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CONFIRMED ADDRESS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedAddress.split(',').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress
                                        .split(',')
                                        .skip(1)
                                        .join(',')
                                        .trim(),
                                    style: const TextStyle(
                                      color: Color(0xFF92A4C9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF92A4C9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135BEC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Confirm Pick-up'),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput(
    String label,
    String hintOrValue,
    IconData icon,
    bool hasBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: hasBorder
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFF324467),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF135BEC),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hintOrValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              hasBorder ? Icons.close : Icons.search,
              color: const Color(0xFF92A4C9),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
