import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

class VehicleSelectionScreen extends ConsumerStatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  ConsumerState<VehicleSelectionScreen> createState() =>
      _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState
    extends ConsumerState<VehicleSelectionScreen> {
  VehicleType? _selectedVehicle;
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  bool _isLoading = false;
  final _userService = UserService();

  @override
  void dispose() {
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your vehicle type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider).value;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _userService.updateUserProfile(user.id, {
        'vehicleType': _selectedVehicle!.name,
        'vehiclePlateNumber': _plateController.text.trim(),
        'vehicleColor': _colorController.text.trim(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/permissions');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Vehicle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you ride?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your mode of transportation for deliveries',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Vehicle Type Cards
            _buildVehicleCard(
              VehicleType.motorcycle,
              '🏍️ Motorcycle',
              'Fast & efficient for small parcels',
            ),
            _buildVehicleCard(
              VehicleType.tricycle,
              '🛺 Tricycle (Keke)',
              'Medium capacity, perfect for local deliveries',
            ),
            _buildVehicleCard(
              VehicleType.car,
              '🚗 Car',
              'Comfortable for longer distances & large items',
            ),
            _buildVehicleCard(
              VehicleType.van,
              '🚚 Van',
              'Maximum capacity for bulk deliveries',
            ),

            const SizedBox(height: 32),

            // Optional Details
            const Text(
              'Vehicle Details (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: 'Plate Number',
                hintText: 'e.g., ABC-123-XY',
                prefixIcon: const Icon(Icons.local_taxi),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: 'Vehicle Color',
                hintText: 'e.g., Black, White, Blue',
                prefixIcon: const Icon(Icons.palette),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 48),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Continue',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleType type, String title, String description) {
    final isSelected = _selectedVehicle == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF135BEC).withValues(alpha: 0.1)
              : Colors.grey[850],
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : Colors.grey[700]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF135BEC),
                size: 28,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[600],
                size: 28,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFF135BEC) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
