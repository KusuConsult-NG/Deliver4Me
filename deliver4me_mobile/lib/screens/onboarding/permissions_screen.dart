import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await Permission.location.status;
    final notification = await Permission.notification.status;
    final camera = await Permission.camera.status;

    if (mounted) {
      setState(() {
        _locationGranted = location.isGranted;
        _notificationGranted = notification.isGranted;
        _cameraGranted = camera.isGranted;
      });
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
        title: const Text('Permissions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's set you up",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'To provide the best delivery experience, Deliver4Me needs access to a few things on your device.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            _buildPermissionSwitch(
              icon: Icons.location_on,
              title: 'Location Services',
              description:
                  'Required to match you with nearby jobs and track parcel routes accurately.',
              value: _locationGranted,
              onChanged: (val) async {
                if (val) await Permission.location.request();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 24),
            _buildPermissionSwitch(
              icon: Icons.notifications,
              title: 'Push Notifications',
              description:
                  'Get instant updates on new job offers, delivery status changes, and payout confirmations.',
              value: _notificationGranted,
              onChanged: (val) async {
                if (val) await Permission.notification.request();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 24),
            _buildPermissionSwitch(
              icon: Icons.camera_alt,
              title: 'Camera Access',
              description:
                  'Needed to scan parcel barcodes for pickup and verify proof of delivery with photos.',
              value: _cameraGranted,
              onChanged: (val) async {
                if (val) await Permission.camera.request();
                _checkPermissions();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'We value your privacy. Your data is never sold.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await [
                    Permission.location,
                    Permission.camera,
                    Permission.notification,
                  ].request();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/tutorial');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white, // Force text color to white
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Allow All',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/tutorial');
                },
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSwitch({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF135BEC), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: const Color(0xFF135BEC),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
