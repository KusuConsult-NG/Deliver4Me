import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:geocoding/geocoding.dart';

class RealGeolocationScreen extends StatefulWidget {
  final bool isPickup;

  const RealGeolocationScreen({
    super.key,
    this.isPickup = true,
  });

  @override
  State<RealGeolocationScreen> createState() => _RealGeolocationScreenState();
}

class _RealGeolocationScreenState extends State<RealGeolocationScreen> {
  String selectedAddress = '';
  double selectedLat = 0.0;
  double selectedLng = 0.0;
  bool isLoading = false;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled. Please enable them.';
          isLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permissions denied';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permissions are permanently denied';
          isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      String addressText =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          addressText =
              '${place.street}, ${place.subLocality}, ${place.locality}';
        }
      } catch (e) {
        debugPrint('Error getting address from coordinates: $e');
      }

      setState(() {
        selectedLat = position.latitude;
        selectedLng = position.longitude;
        selectedAddress = addressText;
        _searchController.text = addressText;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting location: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          selectedLat = loc.latitude;
          selectedLng = loc.longitude;
          selectedAddress = query;
          // _searchController.text = query; // Keep what user typed
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Address not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error searching address: $e';
        isLoading = false;
      });
    }
  }

  void _confirmLocation() {
    if (selectedAddress.isNotEmpty) {
      final locationData = LocationData(
        address: selectedAddress,
        latitude: selectedLat,
        longitude: selectedLng,
      );
      Navigator.pop(context, locationData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickup ? 'Select Pickup' : 'Select Drop-off'),
      ),
      body: Stack(
        children: [
          // Map placeholder (in production, use flutter_map or google_maps_flutter)
          Container(
            color: Colors.grey[850],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Retry GPS'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Icon(Icons.location_on,
                            size: 64, color: Colors.green[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Location Selected',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 32),
                        //   child: Text(
                        //     selectedAddress,
                        //     style: TextStyle(color: Colors.grey[600]),
                        //     textAlign: TextAlign.center,
                        //   ),
                        // ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5), // Shadow for search bar
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search address or zip code...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
          ),

          // Bottom confirmation
          if (selectedAddress.isNotEmpty && !isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Expanded(
                        //   child: OutlinedButton.icon(
                        //     onPressed: _getCurrentLocation,
                        //     icon: const Icon(Icons.refresh),
                        //     label: const Text('Refresh'),
                        //   ),
                        // ),
                        // const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _confirmLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135BEC),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Confirm Location',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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
