import 'package:flutter/material.dart';

class GeolocationSelectionScreen extends StatefulWidget {
  final bool isPickup;

  const GeolocationSelectionScreen({
    super.key,
    this.isPickup = true,
  });

  @override
  State<GeolocationSelectionScreen> createState() =>
      _GeolocationSelectionScreenState();
}

class _GeolocationSelectionScreenState
    extends State<GeolocationSelectionScreen> {
  String searchQuery = '';
  String selectedAddress = '';
  double selectedLat = 0.0;
  double selectedLng = 0.0;

  // Mock addresses for demo
  final mockAddresses = [
    {'address': '123 Main Street, Downtown', 'lat': 40.7128, 'lng': -74.0060},
    {'address': '456 Oak Avenue, Uptown', 'lat': 40.7489, 'lng': -73.9680},
    {'address': '789 Pine Road, Midtown', 'lat': 40.7580, 'lng': -73.9855},
  ];

  void _confirmLocation() {
    if (selectedAddress.isNotEmpty) {
      // Return the selected location
      Navigator.pop(context, {
        'address': selectedAddress,
        'latitude': selectedLat,
        'longitude': selectedLng,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickup ? 'Select Pickup' : 'Select Drop-off'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: Colors.grey[850],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map View',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and address selection overlay
          Column(
            children: [
              // Search bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search location...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),

              // Address suggestions
              if (searchQuery.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: mockAddresses.length,
                      itemBuilder: (context, index) {
                        final addr = mockAddresses[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(addr['address'] as String),
                          onTap: () {
                            setState(() {
                              selectedAddress = addr['address'] as String;
                              selectedLat = addr['lat'] as double;
                              selectedLng = addr['lng'] as double;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),

              const Spacer(),

              // Confirm button
              if (selectedAddress.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135BEC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Confirm Location'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
