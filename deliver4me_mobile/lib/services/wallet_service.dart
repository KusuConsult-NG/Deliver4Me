import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/user_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double _ngnRate = 1500.0; // 1 USD = 1500 NGN

  // Stream of transactions for a user
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  // Add funds or deduct funds with transaction logging and limit enforcement
  Future<void> updateBalanceWithLog({
    required String userId,
    required double amount, // in USD
    required String description,
    required String type, // 'earning', 'top-up', 'payment', 'withdrawal'
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final transactionRef = userRef.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final user = UserModel.fromFirestore(userDoc);
      final amountInNgn = amount.abs() * _ngnRate;

      // 1. Enforce Limits
      if (amount > 0 && type == 'top-up') {
        // Daily Deposit Limit Check
        double todayDeposit = user.currentDailyDeposit;
        final now = DateTime.now();

        // Reset daily deposit if it's a new day
        if (user.lastDepositDate == null ||
            user.lastDepositDate!.day != now.day ||
            user.lastDepositDate!.month != now.month ||
            user.lastDepositDate!.year != now.year) {
          todayDeposit = 0;
        }

        if (todayDeposit + amountInNgn > user.dailyDepositLimit) {
          throw Exception(
              'Daily deposit limit exceeded for your tier (₦${user.dailyDepositLimit})');
        }

        // Max Balance Check
        final newBalanceInNgn = (user.walletBalance + amount) * _ngnRate;
        if (newBalanceInNgn > user.maxBalanceLimit) {
          throw Exception(
              'Maximum wallet balance exceeded for your tier (₦${user.maxBalanceLimit})');
        }

        // Update daily deposit stats
        transaction.update(userRef, {
          'currentDailyDeposit': todayDeposit + amountInNgn,
          'lastDepositDate': FieldValue.serverTimestamp(),
        });
      }

      if (amount < 0 && type == 'withdrawal') {
        // Daily Withdrawal Limit Check
        if (amountInNgn > user.dailyWithdrawalLimit) {
          throw Exception(
              'Withdrawal amount exceeds your daily limit (₦${user.dailyWithdrawalLimit})');
        }

        if (user.walletBalance < amount.abs()) {
          throw Exception('Insufficient funds for withdrawal');
        }
      }

      // 2. Update balance atomically
      transaction.update(userRef, {
        'walletBalance': FieldValue.increment(amount),
      });

      // 3. Log transaction
      transaction.set(transactionRef, {
        'amount': amount,
        'description': description,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
