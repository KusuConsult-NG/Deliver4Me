import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/services/wallet_service.dart';
import 'package:intl/intl.dart';

class RiderWalletScreen extends ConsumerStatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  ConsumerState<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends ConsumerState<RiderWalletScreen> {
  final userService = UserService();
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
            const SizedBox(height: 16),
            const Text(
              'Your Tier limits will be enforced automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    // Use dialogContext for pop if it's still valid, or just simple pop
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

  Future<void> _showWithdrawalDialog() async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw Funds'),
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
            ),
            const SizedBox(height: 8),
            const Text(
              'Funds will be sent to your verified bank account.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      amount: -amount,
                      description: 'Wallet Withdrawal',
                      type: 'withdrawal',
                    );

                    if (!mounted) return;
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Withdrew ₦${amount.toStringAsFixed(2)} successfully'),
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
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: userService.streamUser(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting &&
              !userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = userSnapshot.data;
          if (userData == null) {
            return const Center(child: Text('User not found'));
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: walletService.getTransactionsStream(user.uid),
            builder: (context, transSnapshot) {
              final transactions = transSnapshot.data ?? [];

              return RefreshIndicator(
                onRefresh: () async {}, // Streams handle real-time updates
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₦${userData.walletBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showTopUpDialog,
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text('Top Up',
                                        style: TextStyle(color: Colors.white)),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showWithdrawalDialog,
                                    icon: const Icon(Icons.arrow_upward,
                                        color: Colors.white),
                                    label: const Text('Withdraw',
                                        style: TextStyle(color: Colors.white)),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Transactions List
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (transactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('No transactions yet',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(transactions[index]);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn) {
    final type = txn['type'] as String;
    final isEarning = type == 'earning' || type == 'top-up';
    final amount = txn['amount'];
    final timestamp = txn['timestamp'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEarning ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarning
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
              color: isEarning ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['description'] ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isEarning ? '+' : '-'}₦${amount.toDouble().abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEarning ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
