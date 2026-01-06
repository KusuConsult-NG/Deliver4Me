import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/sender/geolocation_selection_screen.dart';
import 'package:deliver4me_mobile/screens/sender/select_payment_method_screen.dart';

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

  final weightCategories = {
    'Small': {'icon': Icons.inbox, 'weight': '0-2 kg', 'price': 5.0},
    'Medium': {'icon': Icons.shopping_bag, 'weight': '2-10 kg', 'price': 10.0},
    'Large': {'icon': Icons.inventory_2, 'weight': '10-25 kg', 'price': 20.0},
  };

  @override
  void dispose() {
    _parcelDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateEstimatedPrice() {
    if (pickupLocation != null && dropoffLocation != null) {
      final basePrice = weightCategories[selectedWeight]!['price'] as double;
      // Simple distance-based pricing (in production, use actual distance calculation)
      setState(() {
        estimatedPrice = basePrice + 5.0; // +$5 for distance
      });
    }
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => const GeolocationSelectionScreen(isPickup: true),
      ),
    );

    if (result != null) {
      setState(() {
        pickupLocation = result;
      });
      _updateEstimatedPrice();
    }
  }

  Future<void> _selectDropoffLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => const GeolocationSelectionScreen(isPickup: false),
      ),
    );

    if (result != null) {
      setState(() {
        dropoffLocation = result;
      });
      _updateEstimatedPrice();
    }
  }

  Future<void> _createOrder() async {
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

                  const SizedBox(height: 12),

                  // Dropoff Location
                  _buildLocationCard(
                    'Drop-off Location',
                    dropoffLocation?.address ?? 'Select drop-off location',
                    Icons.location_on,
                    _selectDropoffLocation,
                    dropoffLocation != null,
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
                    decoration: const InputDecoration(
                      labelText: 'What are you sending?',
                      hintText: 'e.g. Documents, Electronics, Food',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the parcel';
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
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter recipient name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _recipientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter recipient phone';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'Special instructions',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

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
                            '\$${estimatedPrice.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }
}
