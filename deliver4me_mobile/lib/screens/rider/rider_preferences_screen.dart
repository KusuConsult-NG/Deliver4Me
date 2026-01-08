import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

class RiderPreferencesScreen extends ConsumerStatefulWidget {
  const RiderPreferencesScreen({super.key});

  @override
  ConsumerState<RiderPreferencesScreen> createState() =>
      _RiderPreferencesScreenState();
}

class _RiderPreferencesScreenState
    extends ConsumerState<RiderPreferencesScreen> {
  double _radius = 10.0;
  bool _isLoading = false;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Initialize radius from current user data
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.deliveryRadius != null) {
      _radius = user.deliveryRadius!;
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      await _userService.updateUserProfile(user.id, {
        'deliveryRadius': _radius,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Preferences saved successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving preferences: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Delivery Radius',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only show jobs within this distance from your current location.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1 km'),
                Text(
                  '${_radius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF135BEC)),
                ),
                const Text('100 km'),
              ],
            ),
            Slider(
              value: _radius,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              label: '${_radius.round()} km',
              activeColor: const Color(0xFF135BEC),
              onChanged: (val) {
                setState(() => _radius = val);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF135BEC),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Preferences',
                        style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
