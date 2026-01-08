import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:deliver4me_mobile/screens/common/identity_verification_screen.dart';

import 'package:deliver4me_mobile/services/wallet_service.dart';

class SenderWalletScreen extends ConsumerStatefulWidget {
  const SenderWalletScreen({super.key});

  @override
  ConsumerState<SenderWalletScreen> createState() => _SenderWalletScreenState();
}

class _SenderWalletScreenState extends ConsumerState<SenderWalletScreen> {
  final walletService = WalletService();
  bool _isProcessing = false;

  Future<void> _showTopUpDialog() async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '₦',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (amountController.text.isNotEmpty)
              Text(
                '≈ ₦${((double.tryParse(amountController.text) ?? 0) * 1500).toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Color(0xFF135BEC), fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final authState = ref.read(authStateProvider);
                final user = authState.value;

                if (user != null) {
                  setState(() => _isProcessing = true);
                  try {
                    await walletService.updateBalanceWithLog(
                      userId: user.uid,
                      amount: amount,
                      description: 'Wallet Top Up',
                      type: 'top-up',
                    );

                    if (!mounted) return;
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Added ₦${amount.toStringAsFixed(2)} to wallet'),
                          backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red),
                    );
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                }
              }
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: const Color(0xFF135BEC),
        elevation: 0,
      ),
      body: Builder(builder: (context) {
        if (user != null && user.kycStatus != 'verified') {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline,
                        size: 60, color: Color(0xFF135BEC)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Wallet Locked',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To access your wallet and perform transactions, we need to verify your identity using NIN and BVN as per regulatory requirements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const IdentityVerificationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Verify Identity',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF135BEC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _showTopUpDialog,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF135BEC)))
                            : const Icon(Icons.add, color: Color(0xFF135BEC)),
                        label: Text(_isProcessing ? 'Processing' : 'Top Up',
                            style: const TextStyle(color: Color(0xFF135BEC))),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transaction History
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.id)
                            .collection('transactions')
                            .orderBy('timestamp', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading transactions'));
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 60, color: Colors.grey[800]),
                                  const SizedBox(height: 16),
                                  const Text('No transactions yet'),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final type = data['type'] as String?;
                              final isEarning =
                                  type == 'earning' || type == 'top-up';
                              // Support legacy structure or new type field
                              final isCredit = isEarning;
                              final amount = (data['amount'] ?? 0.0) as double;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isCredit
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color:
                                          isCredit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                      data['description'] ?? 'Transaction'),
                                  subtitle: Text(
                                    data['timestamp'] != null
                                        ? (data['timestamp'] as Timestamp)
                                            .toDate()
                                            .toString()
                                            .split(' ')[0]
                                        : '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '${isCredit ? '+' : '-'}₦${amount.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color:
                                          isCredit ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
