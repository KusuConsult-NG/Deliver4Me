import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/services/card_service.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';

class AddNewCardScreen extends ConsumerStatefulWidget {
  const AddNewCardScreen({super.key});

  @override
  ConsumerState<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends ConsumerState<AddNewCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardService = CardService();

  bool saveAsDefault = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user != null) {
        await _cardService.saveCard(
          userId: user.uid,
          cardNumber: _cardNumberController.text.replaceAll(' ', ''),
          expiryDate: _expiryController.text,
          cardHolder: _cardHolderController.text,
          isDefault: saveAsDefault,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add card: $e'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Card'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Visual Card Preview
              ListenableBuilder(
                listenable: _cardNumberController,
                builder: (context, _) {
                  final number = _cardNumberController.text.isEmpty
                      ? '•••• •••• •••• 1234'
                      : _cardNumberController.text;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 48,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFE55C)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFFD4AF37)
                                          .withValues(alpha: 0.5)),
                                ),
                              ),
                              const Icon(Icons.contactless,
                                  color: Colors.white70, size: 28),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CARD NUMBER',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text(number,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      letterSpacing: 2)),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CARD HOLDER',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 8,
                                          letterSpacing: 0.8)),
                                  SizedBox(height: 4),
                                  Text('JOHN DOE',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('EXPIRES',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 8,
                                          letterSpacing: 0.8)),
                                  SizedBox(height: 4),
                                  Text('12/26',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('VISA',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Form Fields
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {},
                    color: const Color(0xFF135BEC),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.length < 16
                    ? 'Invalid card number'
                    : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'Name on card',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter cardholder name'
                    : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || !value.contains('/')
                              ? 'Invalid date'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () {},
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) => value == null || value.length < 3
                          ? 'Invalid CVV'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Save as default',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use for future deliveries',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: saveAsDefault,
                      onChanged: (value) {
                        setState(() => saveAsDefault = value);
                      },
                      activeTrackColor: const Color(0xFF135BEC),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '128-bit SSL Secured Connection',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100), // Bottom padding for button
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSaveCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Update Card'),
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
}
