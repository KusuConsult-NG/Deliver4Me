import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create new order
  Future<String> createOrder({
    required String senderId,
    required LocationData pickup,
    required LocationData dropoff,
    required String parcelDescription,
    required String weightCategory,
    required String paymentMethod,
  }) async {
    try {
      final orderId = _uuid.v4();
      final deliveryCode = _generateDeliveryCode();
      final price = _calculatePrice(pickup, dropoff, weightCategory);

      final order = OrderModel(
        id: orderId,
        senderId: senderId,
        status: OrderStatus.pending,
        pickup: pickup,
        dropoff: dropoff,
        parcelDescription: parcelDescription,
        weightCategory: weightCategory,
        price: price,
        paymentMethod: paymentMethod,
        deliveryCode: deliveryCode,
        timeline: [
          TimelineEvent(
            title: 'Order Created',
            description: 'Searching for available riders',
            timestamp: DateTime.now(),
            isComplete: true,
          ),
        ],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('orders')
          .doc(orderId)
          .set(order.toFirestore());

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Stream order (real-time updates)
  Stream<OrderModel?> streamOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  // Get user orders (sender)
  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get rider orders
  Stream<List<OrderModel>> streamRiderOrders(String riderId) {
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get available jobs for riders
  Stream<List<OrderModel>> streamAvailableJobs() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Accept order (rider)
  Future<void> acceptOrder(String orderId, String riderId) async {
    try {
      final Map<String, dynamic> updates = {
        'riderId': riderId,
        'status': OrderStatus.accepted.toString().split('.').last,
        'acceptedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([
          TimelineEvent(
            title: 'Rider Assigned',
            description: 'Rider is on the way to pickup',
            timestamp: DateTime.now(),
            isComplete: true,
          ).toMap(),
        ]),
      };

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Failed to accept order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? timelineTitle,
    String? timelineDescription,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };

      if (timelineTitle != null && timelineDescription != null) {
        updates['timeline'] = FieldValue.arrayUnion([
          TimelineEvent(
            title: timelineTitle,
            description: timelineDescription,
            timestamp: DateTime.now(),
            isComplete: true,
          ).toMap(),
        ]);
      }

      if (status == OrderStatus.delivered) {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Verify delivery code
  Future<bool> verifyDeliveryCode(String orderId, String code) async {
    try {
      final order = await getOrderById(orderId);
      return order?.deliveryCode == code;
    } catch (e) {
      return false;
    }
  }

  // Calculate price based on distance and weight
  double _calculatePrice(
    LocationData pickup,
    LocationData dropoff,
    String weightCategory,
  ) {
    final distance = _calculateDistance(
      pickup.latitude,
      pickup.longitude,
      dropoff.latitude,
      dropoff.longitude,
    );

    // Base price + distance price + weight multiplier
    double basePrice = 5.0;
    double pricePerKm = 2.0;
    double weightMultiplier = 1.0;

    switch (weightCategory.toLowerCase()) {
      case 'small':
        weightMultiplier = 1.0;
        break;
      case 'medium':
        weightMultiplier = 1.5;
        break;
      case 'large':
        weightMultiplier = 2.0;
        break;
      case 'extra large':
        weightMultiplier = 2.5;
        break;
    }

    return (basePrice + (distance * pricePerKm)) * weightMultiplier;
  }

  // Calculate distance (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Generate 4-digit delivery code
  String _generateDeliveryCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }
}
