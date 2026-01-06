import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/payment_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/config/firebase_config.dart';
import 'package:deliver4me_mobile/screens/sender/payment_confirmation_screen.dart';
import 'package:uuid/uuid.dart';

class SelectPaymentMethodScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;

  const SelectPaymentMethodScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  ConsumerState<SelectPaymentMethodScreen> createState() =>
      _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState
    extends ConsumerState<SelectPaymentMethodScreen> {
  final paymentService = PaymentService(FirebaseConfig.paystackPublicKey);
  final userService = UserService();
  final orderService = OrderService();

  String selectedMethod = 'card';
  bool isLoading = false;
  double walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user != null) {
        final userData = await userService.getUserById(user.uid);
        if (userData != null && mounted) {
          setState(() {
            walletBalance = userData.walletBalance;
          });
        }
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
    }
  }

  Future<void> _processPayment() async {
    setState(() => isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('No user logged in');
      }

      if (selectedMethod == 'wallet') {
        await _processWalletPayment(user.uid);
      } else {
        await _processCardPayment(user.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _processWalletPayment(String userId) async {
    if (walletBalance < widget.amount) {
      throw Exception('Insufficient wallet balance');
    }

    // Deduct from wallet
    await userService.updateWalletBalance(userId, -widget.amount);

    // Update order status
    await orderService.updateOrderStatus(widget.orderId, 'confirmed');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            orderId: widget.orderId,
            amount: widget.amount,
            paymentMethod: 'Wallet',
          ),
        ),
      );
    }
  }

  Future<void> _processCardPayment(String userId) async {
    final reference = 'ORDER_${const Uuid().v4()}';

    try {
      // Initialize Paystack transaction
      final result = await paymentService.initializeTransaction(
        email: ref.read(authStateProvider).value?.email ?? '',
        amount: widget.amount,
        reference: reference,
      );

      // In a real app, you would open the authorization_url in a webview
      // For demo purposes, we'll simulate a successful payment
      final authUrl = result['authorization_url'];

      // TODO: Open webview with authUrl
      // For now, simulate payment after delay
      await Future.delayed(const Duration(seconds: 1));

      // Verify payment (in real app, this would be after webview returns)
      final verifiedResult = await paymentService.verifyTransaction(reference);

      if (verifiedResult['status'] == 'success') {
        // Update order status
        await orderService.updateOrderStatus(widget.orderId, 'confirmed');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationScreen(
                orderId: widget.orderId,
                amount: widget.amount,
                paymentMethod: 'Card',
              ),
            ),
          );
        }
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      throw Exception('Card payment failed: $e');
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
        title: const Text('Payment Method'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Total',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'SELECT PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Wallet Option
                _buildPaymentOption(
                  'wallet',
                  Icons.account_balance_wallet,
                  'Deliver4Me Wallet',
                  'Balance: \$${walletBalance.toStringAsFixed(2)}',
                  walletBalance >= widget.amount,
                ),

                // Card Option
                _buildPaymentOption(
                  'card',
                  Icons.credit_card,
                  'Credit/Debit Card',
                  'Pay with Paystack',
                  true,
                ),

                const SizedBox(height: 24),

                // Security Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Payments are secure and encrypted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total to pay',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '\$${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _processPayment,
                  child: const Text('Confirm Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    IconData icon,
    String title,
    String subtitle,
    bool isEnabled,
  ) {
    final isSelected = selectedMethod == value;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap:
              isEnabled ? () => setState(() => selectedMethod = value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF135BEC) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF135BEC) : Colors.grey[800],
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF135BEC) : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
