import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Save token to user profile for later use
      if (token != null) {
        // Store in Firestore (you can update this in auth flow)
        debugPrint('Store FCM token: $token');
      }
    }
  }

  // Send delivery code notification to sender
  Future<void> sendDeliveryCodeNotification({
    required String userId,
    required String orderId,
    required String deliveryCode,
    required String recipientName,
  }) async {
    try {
      // Create in-app notification document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'delivery_code',
        'title': 'Delivery Code Generated',
        'body':
            'Your delivery code is: $deliveryCode. Share this with $recipientName.',
        'deliveryCode': deliveryCode,
        'orderId': orderId,
        'recipientName': recipientName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Delivery code notification sent to user $userId');
    } catch (e) {
      debugPrint('Error sending delivery code notification: $e');
    }
  }

  // Send reminder to share delivery code
  Future<void> sendDeliveryCodeReminder({
    required String userId,
    required String orderId,
    required String deliveryCode,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'delivery_code_reminder',
        'title': 'Don\'t Forget!',
        'body':
            'Remember to share delivery code $deliveryCode with your recipient.',
        'deliveryCode': deliveryCode,
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Delivery code reminder sent to user $userId');
    } catch (e) {
      debugPrint('Error sending reminder: $e');
    }
  }

  // Get notifications stream for a user
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}
