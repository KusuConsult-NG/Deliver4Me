import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  deposit,
  withdrawal,
  payment,
  earning,
  refund,
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String status;
  final DateTime timestamp;
  final String? orderId;
  final String? paymentMethod;
  final String? reference;
  final String? description;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.orderId,
    this.paymentMethod,
    this.reference,
    this.description,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.payment,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      orderId: data['orderId'],
      paymentMethod: data['paymentMethod'],
      reference: data['reference'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      if (orderId != null) 'orderId': orderId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (reference != null) 'reference': reference,
      if (description != null) 'description': description,
    };
  }
}
