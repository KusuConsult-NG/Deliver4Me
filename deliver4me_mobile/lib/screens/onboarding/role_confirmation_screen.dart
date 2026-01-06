import 'package:flutter/material.dart';

class RoleConfirmationScreen extends StatefulWidget {
  const RoleConfirmationScreen({super.key});

  @override
  State<RoleConfirmationScreen> createState() => _RoleConfirmationScreenState();
}

class _RoleConfirmationScreenState extends State<RoleConfirmationScreen> {
  bool isRider = true;
  String selectedVehicle = 'Scooter';
  double deliveryRadius = 15;
  Set<String> selectedZones = {'Downtown'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101622),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Setup Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressBar(false),
                const SizedBox(width: 8),
                _buildProgressBar(true),
                const SizedBox(width: 8),
                _buildProgressBar(false),
              ],
            ),

            const SizedBox(height: 32),

            // Hero Image
            Container(
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF135BEC).withValues(alpha: 0.3),
                    const Color(0xFF135BEC).withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'How will you use Deliver4Me?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role to customize your experience.',
              style: TextStyle(
                color: Color(0xFF92A4C9),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Role Selector
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard(
                    icon: Icons.inventory_2,
                    title: 'Sender',
                    subtitle: 'I want to send parcels',
                    isSelected: !isRider,
                    onTap: () => setState(() => isRider = false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRoleCard(
                    icon: Icons.two_wheeler,
                    title: 'Rider',
                    subtitle: 'I want to earn money',
                    isSelected: isRider,
                    onTap: () => setState(() => isRider = true),
                  ),
                ),
              ],
            ),

            if (isRider) ...[
              const SizedBox(height: 32),
              const Text(
                'Rider Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Vehicle Type
              const Text(
                'VEHICLE TYPE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildVehicleOption('Bike', Icons.pedal_bike),
                  const SizedBox(width: 12),
                  _buildVehicleOption('Scooter', Icons.moped),
                  const SizedBox(width: 12),
                  _buildVehicleOption('Car', Icons.directions_car),
                  const SizedBox(width: 12),
                  _buildVehicleOption('Van', Icons.local_shipping),
                ],
              ),

              const SizedBox(height: 24),

              // Delivery Radius
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PREFERRED RADIUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${deliveryRadius.toInt()} km',
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF135BEC),
                  inactiveTrackColor: const Color(0xFF324467),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF135BEC).withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: deliveryRadius,
                  min: 1,
                  max: 50,
                  onChanged: (value) {
                    setState(() => deliveryRadius = value);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 KM',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '50 KM',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Active Zones
              const Text(
                'ACTIVE ZONES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildZoneChip('Downtown', true),
                  _buildZoneChip('North Hills', false),
                  _buildZoneChip('Industrial Park', false),
                  _buildAddZoneChip(),
                ],
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
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
                  Text('Continue'),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isActive) {
    return Container(
      width: isActive ? 32 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF135BEC) : const Color(0xFF324467),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF135BEC).withValues(alpha: 0.1)
              : const Color(0xFF1C2433),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF135BEC) : const Color(0xFF324467),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isSelected)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF135BEC),
                  size: 20,
                ),
              ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF135BEC)
                    : const Color(0xFF324467),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF135BEC) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF135BEC).withValues(alpha: 0.8)
                    : const Color(0xFF92A4C9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption(String label, IconData icon) {
    final isSelected = selectedVehicle == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedVehicle = label),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF135BEC).withValues(alpha: 0.1)
                : const Color(0xFF1C2433),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF135BEC)
                  : const Color(0xFF324467),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF135BEC)
                    : const Color(0xFF92A4C9),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF135BEC)
                      : const Color(0xFF92A4C9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedZones.contains(label)) {
            selectedZones.remove(label);
          } else {
            selectedZones.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135BEC) : const Color(0xFF1C2433),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF135BEC) : const Color(0xFF324467),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF92A4C9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddZoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF324467),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add,
            color: Color(0xFF92A4C9),
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Add',
            style: TextStyle(
              color: Color(0xFF92A4C9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
