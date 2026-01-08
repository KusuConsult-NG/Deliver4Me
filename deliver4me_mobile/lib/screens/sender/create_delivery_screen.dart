import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/sender/real_geolocation_screen.dart';
import 'package:deliver4me_mobile/screens/sender/select_payment_method_screen.dart';
import 'dart:math';

class CreateDeliveryScreen extends ConsumerStatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  ConsumerState<CreateDeliveryScreen> createState() =>
      _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends ConsumerState<CreateDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parcelDescriptionController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  final orderService = OrderService();

  LocationData? pickupLocation;
  LocationData? dropoffLocation;
  String selectedWeight = 'Small';
  double estimatedPrice = 0.0;
  bool isLoading = false;
  bool _isUrgent = false;
  bool _isASAP = true;

  final _pickupDetailController = TextEditingController();
  final _dropoffDetailController = TextEditingController();
  final _bidPriceController = TextEditingController();

  double? _calculatedDistance;
  bool _showBiddingUI = false;

  final weightCategories = {
    'Small': {'icon': Icons.inbox, 'weight': '0-2 kg', 'price': 5.0},
    'Medium': {'icon': Icons.shopping_bag, 'weight': '2-10 kg', 'price': 10.0},
    'Large': {'icon': Icons.inventory_2, 'weight': '10-25 kg', 'price': 20.0},
    'Heavy': {'icon': Icons.local_shipping, 'weight': '> 25 kg', 'price': 40.0},
  };

  @override
  void dispose() {
    _parcelDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    _pickupDetailController.dispose();
    _dropoffDetailController.dispose();
    _bidPriceController.dispose();
    super.dispose();
  }

  double _calculateDistance(LocationData pickup, LocationData dropoff) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(dropoff.latitude - pickup.latitude);
    final dLon = _toRadians(dropoff.longitude - pickup.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(pickup.latitude)) *
            cos(_toRadians(dropoff.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _updateEstimatedPrice() {
    if (pickupLocation != null && dropoffLocation != null) {
      final basePrice = weightCategories[selectedWeight]!['price'] as double;
      // Simple distance-based pricing (in production, use actual distance calculation)
      setState(() {
        estimatedPrice = basePrice + 5.0; // +$5 for distance
        if (_isUrgent) estimatedPrice += 50.0;
      });
    }
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => const RealGeolocationScreen(isPickup: true),
      ),
    );

    if (result != null) {
      setState(() {
        pickupLocation = result;
        // Calculate distance if both locations are set
        if (dropoffLocation != null) {
          _calculatedDistance = _calculateDistance(result, dropoffLocation!);
          _showBiddingUI = _calculatedDistance! > 50;
        }
      });
      _updateEstimatedPrice();
    }
  }

  Future<void> _selectDropoffLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => const RealGeolocationScreen(isPickup: false),
      ),
    );

    if (result != null) {
      setState(() {
        dropoffLocation = result;
        // Calculate distance if both locations are set
        if (pickupLocation != null) {
          _calculatedDistance = _calculateDistance(pickupLocation!, result);
          _showBiddingUI = _calculatedDistance! > 50;
        }
      });
      _updateEstimatedPrice();
    }
  }

  Future<void> _createOrder() async {
    if (pickupLocation == null || dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop-off locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (pickupLocation == null || dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and dropoff locations'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to create an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create the order
      // Parse bid price if provided for long distance
      double? bidPrice;
      if (_showBiddingUI && _bidPriceController.text.isNotEmpty) {
        bidPrice = double.tryParse(_bidPriceController.text);
      }

      final orderId = await orderService.createOrder(
        senderId: user.uid,
        pickup: pickupLocation!,
        dropoff: dropoffLocation!,
        parcelDescription: _parcelDescriptionController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        weightCategory: selectedWeight,
        paymentMethod: 'pending', // Will be updated after payment
        notes: _notesController.text.trim(),
        isUrgent: _isUrgent,
        isASAP: _isASAP,
        bidPrice: bidPrice, // Pass bid price for 50km+ orders
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to payment screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectPaymentMethodScreen(
              orderId: orderId,
              amount: estimatedPrice,
            ),
          ),
        );

        if (result == true && mounted) {
          // Payment successful, go to tracking
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Delivery'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Selection
                  const Text(
                    'Delivery Route',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Pickup Location
                  _buildLocationCard(
                    'Pickup Location',
                    pickupLocation?.address ?? 'Select pickup location',
                    Icons.my_location,
                    _selectPickupLocation,
                    pickupLocation != null,
                  ),
                  if (pickupLocation != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: TextFormField(
                        controller: _pickupDetailController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Pickup Building / Flat / Instructions',
                          hintText: 'e.g. Blue Gate, Flat 4B',
                          prefixIcon: Icon(Icons.meeting_room, size: 18),
                          isDense: true,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Dropoff Location
                  _buildLocationCard(
                    'Drop-off Location',
                    dropoffLocation?.address ?? 'Select drop-off location',
                    Icons.location_on,
                    _selectDropoffLocation,
                    dropoffLocation != null,
                  ),
                  if (dropoffLocation != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: TextFormField(
                        controller: _dropoffDetailController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Drop-off Building / Flat / Instructions',
                          hintText: 'e.g. Reception, Ask for John',
                          prefixIcon: Icon(Icons.meeting_room, size: 18),
                          isDense: true,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Parcel Details
                  const Text(
                    'Parcel Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _parcelDescriptionController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'What are you sending?',
                      hintText: 'e.g. Documents, Electronics, Food',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe the parcel';
                      }
                      if (value.trim().length < 3) {
                        return 'Description is too short';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Weight Category
                  const Text(
                    'Select Weight',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: weightCategories.keys.map((weight) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildWeightCard(weight),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Recipient Details
                  const Text(
                    'Recipient Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _recipientNameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter recipient name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _recipientPhoneController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Recipient Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter recipient phone';
                      }
                      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'Special instructions',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Switches
                  SwitchListTile(
                    title: const Text('Deliver ASAP'),
                    subtitle:
                        const Text('Rider will head to pickup immediately'),
                    value: _isASAP,
                    activeThumbColor: const Color(0xFF135BEC),
                    onChanged: (val) {
                      setState(() => _isASAP = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Row(
                      children: [
                        Text('Urgent Delivery'),
                        SizedBox(width: 8),
                        Icon(Icons.flash_on, color: Colors.orange, size: 20),
                      ],
                    ),
                    subtitle:
                        const Text('Priority matching + Urgent Badge (+₦50)'),
                    value: _isUrgent,
                    activeThumbColor: Colors.orange,
                    onChanged: (val) {
                      setState(() {
                        _isUrgent = val;
                        _updateEstimatedPrice();
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Bidding UI for 50km+ orders
                  if (_showBiddingUI && _calculatedDistance != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Long Distance: ${_calculatedDistance!.toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Distance exceeds 50km. Please set your custom price:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bidPriceController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Your Proposed Price',
                              prefixText: '₦',
                              hintText: '3000',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Riders can accept or reject your offer',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                  // Price Summary
                  if (estimatedPrice > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Cost',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₦${estimatedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isLoading ? null : _createOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Continue to Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF135BEC).withValues(alpha: 0.1)
              : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF135BEC) : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(String weight) {
    final isSelected = selectedWeight == weight;
    final data = weightCategories[weight]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWeight = weight;
        });
        _updateEstimatedPrice();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135BEC) : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              data['icon'] as IconData,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              weight,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            Text(
              data['weight'] as String,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            // Vehicle Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getVehicleHint(weight),
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleHint(String weight) {
    switch (weight) {
      case 'Small':
        return 'Motorcycle';
      case 'Medium':
        return 'Bike/Car';
      case 'Large':
        return 'Car Selected';
      case 'Heavy':
        return 'Van Required';
      default:
        return 'Standard';
    }
  }
}
