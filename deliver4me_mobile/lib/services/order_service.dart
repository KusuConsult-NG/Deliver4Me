import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:deliver4me_mobile/services/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _notificationService = NotificationService();

  // Create new order
  Future<String> createOrder({
    required String senderId,
    required LocationData pickup,
    required LocationData dropoff,
    required String parcelDescription,
    required String weightCategory,
    required String paymentMethod,
    required String recipientName,
    required String recipientPhone,
    String notes = '',
    bool isUrgent = false,
    bool isASAP = false,
    double? bidPrice,
  }) async {
    try {
      final orderId = _uuid.v4();
      final deliveryCode = _generateDeliveryCode();
      final price =
          _calculatePrice(pickup, dropoff, weightCategory, bidPrice: bidPrice);

      double finalPrice = price;
      if (isUrgent) finalPrice += 50.0; // Urgent fee

      // Calculate commission and rider earnings
      final platformCommission = (finalPrice * 0.10).roundToDouble(); // 10%
      final riderEarnings =
          (finalPrice - platformCommission).roundToDouble(); // 90%

      final order = OrderModel(
        id: orderId,
        senderId: senderId,
        status: OrderStatus.pending,
        pickup: pickup,
        dropoff: dropoff,
        parcelDescription: parcelDescription,
        weightCategory: weightCategory,
        price: finalPrice,
        paymentMethod: paymentMethod,
        deliveryCode: deliveryCode,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        notes: notes,
        isUrgent: isUrgent,
        isASAP: isASAP,
        platformCommission: platformCommission,
        riderEarnings: riderEarnings,
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

      // Trigger: Notify nearby riders (Simulated)
      debugPrint(
          'PUSH NOTIFICATION: New delivery available at ${pickup.address}');

      // Send delivery code notification to sender
      await _notificationService.sendDeliveryCodeNotification(
        userId: senderId,
        orderId: orderId,
        deliveryCode: deliveryCode,
        recipientName: recipientName,
      );

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
        .where('status', isEqualTo: OrderStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Accept order (rider) with transaction to prevent race conditions
  Future<void> acceptOrder(String orderId, String riderId) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderRef);

        if (!snapshot.exists) {
          throw Exception('Order does not exist');
        }

        final status = snapshot.get('status') as String;
        if (status != 'pending') {
          throw Exception('Order is no longer available');
        }

        transaction.update(orderRef, {
          'riderId': riderId,
          'status': OrderStatus.accepted.toString().split('.').last,
          'acceptedAt': FieldValue.serverTimestamp(),
          'timeline': FieldValue.arrayUnion([
            {
              'title': 'Rider Assigned',
              'description': 'A rider is on the way to pickup',
              'timestamp': Timestamp.now(),
              'isComplete': true,
            }
          ]),
        });

        // Trigger: Notify sender (Simulated)
        debugPrint(
            'PUSH NOTIFICATION TO SENDER: Your order has been accepted by a rider!');
      });
    } catch (e) {
      throw Exception('Failed to accept order: $e');
    }
  }

  // Cancel order with validation
  Future<void> cancelOrder(String orderId,
      {String reason = 'Cancelled by user'}) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await orderRef.get();

      if (!snapshot.exists) {
        throw Exception('Order does not exist');
      }

      final statusStr = snapshot.get('status') as String;
      final status = OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusStr,
        orElse: () => OrderStatus.pending,
      );

      // Cannot cancel if already picked up or delivered
      if (status == OrderStatus.pickedUp ||
          status == OrderStatus.inTransit ||
          status == OrderStatus.delivered) {
        throw Exception('Cannot cancel order after it has been picked up');
      }

      await updateOrderStatus(
        orderId,
        OrderStatus.cancelled,
        timelineTitle: 'Order Cancelled',
        timelineDescription: reason,
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
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

      // Set specific timestamps based on status
      if (status == OrderStatus.pickedUp) {
        updates['pickedUpAt'] = FieldValue.serverTimestamp();
      } else if (status == OrderStatus.delivered) {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      }

      // Automatically determine timeline info if not provided
      String title = timelineTitle ?? '';
      String desc = timelineDescription ?? '';

      if (title.isEmpty) {
        switch (status) {
          case OrderStatus.accepted:
            title = 'Rider Assigned';
            desc = 'A rider has accepted your delivery';
            break;
          case OrderStatus.pickedUp:
            title = 'Parcel Picked Up';
            desc = 'The rider has collected your parcel';
            break;
          case OrderStatus.inTransit:
            title = 'In Transit';
            desc = 'Your parcel is on the way';
            break;
          case OrderStatus.delivered:
            title = 'Delivered';
            desc = 'Parcel successfully delivered';
            break;
          case OrderStatus.cancelled:
            title = 'Cancelled';
            desc = 'The order has been cancelled';
            break;
          default:
            break;
        }
      }

      if (title.isNotEmpty) {
        updates['timeline'] = FieldValue.arrayUnion([
          {
            'title': title,
            'description': desc,
            'timestamp': Timestamp.now(), // Fixed time for the entry log
            'isComplete': true,
          }
        ]);
      }

      await _firestore.collection('orders').doc(orderId).update(updates);

      // Trigger: Notify sender/rider of status update (Simulated)
      debugPrint('PUSH NOTIFICATION: Order status updated to $title');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update rider location for real-time tracking
  Future<void> updateRiderLocation(
      String orderId, double latitude, double longitude) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'riderLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('Failed to update rider location: $e');
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

  // Mark rider arrival at pickup location
  Future<void> markArrivedAtPickup(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'arrivedAtPickupTime': FieldValue.serverTimestamp(),
      });

      // Send notification to sender about arrival
      final order = await getOrderById(orderId);
      if (order != null) {
        await _notificationService.sendDeliveryCodeNotification(
          userId: order.senderId,
          orderId: orderId,
          deliveryCode: order.deliveryCode,
          recipientName: 'Rider has arrived at pickup location',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark arrival at pickup: $e');
    }
  }

  // Mark rider arrival at dropoff location
  Future<void> markArrivedAtDropoff(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'arrivedAtDropoffTime': FieldValue.serverTimestamp(),
      });

      // Send notification to sender about arrival
      final order = await getOrderById(orderId);
      if (order != null) {
        await _notificationService.sendDeliveryCodeNotification(
          userId: order.senderId,
          orderId: orderId,
          deliveryCode: order.deliveryCode,
          recipientName: 'Rider has arrived at dropoff location',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark arrival at dropoff: $e');
    }
  }

  // Calculate and notify sender about waiting charges
  Future<void> notifyWaitingCharges(
      String orderId, double waitingCharges) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null || waitingCharges <= 0) return;

      await _notificationService.sendDeliveryCodeNotification(
        userId: order.senderId,
        orderId: orderId,
        deliveryCode: '₦${waitingCharges.toStringAsFixed(0)}',
        recipientName: 'Waiting charge applied for delayed pickup/dropoff',
      );
    } catch (e) {
      debugPrint('Error notifying waiting charges: $e');
    }
  }

  // Calculate price based on distance and weight
  double _calculatePrice(
    LocationData pickup,
    LocationData dropoff,
    String weightCategory, {
    double? bidPrice,
  }) {
    final distance = _calculateDistance(
      pickup.latitude,
      pickup.longitude,
      dropoff.latitude,
      dropoff.longitude,
    );

    // For distances > 50km with custom bid price
    if (distance > 50 && bidPrice != null) {
      return bidPrice;
    }

    // Base price: ₦1,200 for up to 10km
    double basePrice = 1200.0;

    if (distance <= 10) {
      return basePrice;
    }

    // 10-50km: ₦1,200 + ₦50/km for distance beyond 10km
    double additionalDistance = distance - 10;
    double pricePerKm = 50.0;
    double price = basePrice + (additionalDistance * pricePerKm);

    // Weight multiplier
    double weightMultiplier = 1.0;
    switch (weightCategory.toLowerCase()) {
      case 'small':
        weightMultiplier = 1.0;
        break;
      case 'medium':
        weightMultiplier = 1.2;
        break;
      case 'large':
        weightMultiplier = 1.5;
        break;
      case 'extra large':
        weightMultiplier = 2.0;
        break;
    }

    return (price * weightMultiplier).roundToDouble();
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
