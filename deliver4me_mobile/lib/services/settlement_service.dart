import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/services/wallet_service.dart';
import 'package:flutter/foundation.dart';

class SettlementService {
  final WalletService _walletService = WalletService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate 10% platform commission
  static double calculatePlatformCommission(double price) {
    return (price * 0.10).roundToDouble();
  }

  // Calculate rider earnings (90% of price)
  static double calculateRiderEarnings(double price) {
    final commission = calculatePlatformCommission(price);
    return (price - commission).roundToDouble();
  }

  // Calculate waiting charges (₦100/min from 2nd minute)
  static double calculateWaitingCharges(
      DateTime arrivedTime, DateTime actionTime) {
    final waitingMinutes = actionTime.difference(arrivedTime).inMinutes;

    // Free for first minute, ₦100/min after
    if (waitingMinutes <= 1) return 0.0;

    final chargeableMinutes = waitingMinutes - 1;
    return (chargeableMinutes * 100.0).roundToDouble(); // ₦100/minute
  }

  // Auto-settle rider on delivery completion
  Future<void> settleRider(OrderModel order) async {
    if (order.fundsReleasedToRider) {
      debugPrint('Funds already released for order ${order.id}');
      return;
    }

    if (order.riderId == null) {
      debugPrint('No rider assigned for order ${order.id}');
      return;
    }

    try {
      final totalPayout = order.riderEarnings + order.waitingCharges;

      debugPrint(
          'Settling rider ${order.riderId} for order ${order.id}: ₦$totalPayout');

      // Add to rider's app wallet
      await _walletService.updateBalanceWithLog(
        userId: order.riderId!,
        amount: totalPayout,
        type: 'earning',
        description:
            'Delivery #${order.id.substring(0, 8)} (₦${order.riderEarnings.toStringAsFixed(0)} + ₦${order.waitingCharges.toStringAsFixed(0)} wait)',
      );

      debugPrint('Added ₦$totalPayout to rider wallet');

      // Mark as settled
      await _firestore.collection('orders').doc(order.id).update({
        'fundsReleasedToRider': true,
        'settlementDate': FieldValue.serverTimestamp(),
      });

      debugPrint('Settlement completed for order ${order.id}');
    } catch (e) {
      debugPrint('Error settling rider for order ${order.id}: $e');
      rethrow;
    }
  }

  // Get total platform earnings
  Future<double> getPlatformEarnings(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered');

      if (startDate != null) {
        query = query.where('deliveredAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('deliveredAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double totalCommission = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalCommission += (data['platformCommission'] ?? 0.0);
      }

      return totalCommission;
    } catch (e) {
      debugPrint('Error calculating platform earnings: $e');
      return 0.0;
    }
  }
}
