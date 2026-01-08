import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:deliver4me_mobile/services/auth_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/services/payment_service.dart';
import 'package:deliver4me_mobile/shared/location_service.dart';
import 'package:deliver4me_mobile/config/firebase_config.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final List<Map<String, dynamic>> _testResults = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    // Test 1: Firebase Initialization
    await _testFirebase();

    // Test 2: Auth Service
    await _testAuthService();

    // Test 3: User Service
    await _testUserService();

    // Test 4: Order Service
    await _testOrderService();

    // Test 5: Payment Service
    await _testPaymentService();

    // Test 6: Location Service
    await _testLocationService();

    setState(() => _isRunning = false);
  }

  Future<void> _testFirebase() async {
    try {
      // Check if Firebase is initialized
      final app = Firebase.app();
      _addResult('Firebase', true, 'Connected to ${app.options.projectId}');
    } catch (e) {
      _addResult('Firebase', false, 'Not initialized: $e');
    }
  }

  Future<void> _testAuthService() async {
    try {
      final authService = AuthService();
      final hasUser = authService.currentUser != null;
      _addResult('Auth Service', true,
          hasUser ? 'User logged in' : 'Service ready, no user');
    } catch (e) {
      _addResult('Auth Service', false, 'Error: $e');
    }
  }

  Future<void> _testUserService() async {
    try {
      UserService();
      _addResult('User Service', true, 'Service initialized');
    } catch (e) {
      _addResult('User Service', false, 'Error: $e');
    }
  }

  Future<void> _testOrderService() async {
    try {
      OrderService();
      _addResult('Order Service', true, 'Service initialized');
    } catch (e) {
      _addResult('Order Service', false, 'Error: $e');
    }
  }

  Future<void> _testPaymentService() async {
    try {
      PaymentService(FirebaseConfig.paystackPublicKey);
      final hasKey = FirebaseConfig.paystackPublicKey.isNotEmpty;
      _addResult('Payment Service', hasKey,
          hasKey ? 'Paystack configured' : 'No API key');
    } catch (e) {
      _addResult('Payment Service', false, 'Error: $e');
    }
  }

  Future<void> _testLocationService() async {
    try {
      final position = await LocationService.getCurrentLocation();
      _addResult(
        'Location Service',
        position != null,
        position != null
            ? 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
            : 'Permissions not granted',
      );
    } catch (e) {
      _addResult('Location Service', false, 'Error: $e');
    }
  }

  void _addResult(String service, bool success, String message) {
    setState(() {
      _testResults.add({
        'service': service,
        'success': success,
        'message': message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runTests,
          ),
        ],
      ),
      body: _isRunning
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      result['success'] ? Icons.check_circle : Icons.error,
                      color: result['success'] ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      result['service'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(result['message']),
                  ),
                );
              },
            ),
    );
  }
}
