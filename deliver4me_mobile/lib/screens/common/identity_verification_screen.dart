import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/kyc_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ninController = TextEditingController();
  final _bvnController = TextEditingController();
  final _kycService = KycService();
  final _userService = UserService();
  bool _isLoading = false;

  @override
  void dispose() {
    _ninController.dispose();
    _bvnController.dispose();
    super.dispose();
  }

  Future<void> _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider).value;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Verify NIN
      final ninValid = await _kycService.verifyIdentity(
        number: _ninController.text.trim(),
        type: 'NIN',
        role: user.role,
      );

      // 2. Verify BVN
      final bvnValid = await _kycService.verifyIdentity(
        number: _bvnController.text.trim(),
        type: 'BVN',
        role: user.role,
      );

      if (ninValid && bvnValid) {
        // Success: Update User Profile
        await _userService.updateUserProfile(user.id, {
          'kycStatus': 'verified',
          'isVerified': true, // For riders
          // In a real app, we might store a hash or partial ID, never the full ID in cleartext
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identity verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed. Please check your details.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    final user = ref.watch(currentUserProvider).value;
    final isRider = user?.role == UserRole.rider;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image or Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user,
                      size: 60, color: Color(0xFF135BEC)),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isRider ? 'Rider Verification' : 'Wallet Activation',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isRider
                    ? 'To accept jobs and ensure safety, we need to verify your identity using NIN and BVN.'
                    : 'To access your wallet and perform transactions, regulatory compliance requires NIN and BVN verification.',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // NIN Field
              TextFormField(
                controller: _ninController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: 'National Identity Number (NIN)',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 11) {
                    return 'Please enter a valid 11-digit NIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // BVN Field
              TextFormField(
                controller: _bvnController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: 'Bank Verification Number (BVN)',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 11) {
                    return 'Please enter a valid 11-digit BVN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Your data is encrypted and secure with Prembly.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyIdentity,
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
                          'Verify Identity',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              if (!isRider) ...[
                const SizedBox(height: 16),
                Center(
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Do this later'))),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
