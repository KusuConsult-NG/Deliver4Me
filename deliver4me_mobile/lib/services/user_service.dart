import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Stream user data
  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update user model (wraps updateProfile)
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update rider online status
  Future<void> updateRiderStatus(String riderId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(riderId).update({
        'isOnline': isOnline,
      });
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Update rider location (for real-time tracking)
  Future<void> updateRiderLocation(
    String riderId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore.collection('users').doc(riderId).update({
        'lastLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  // Upload profile photo URL
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('Failed to update photo: $e');
    }
  }

  // Rate a user
  Future<void> rateUser(String userId, double rating, String comment) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) throw Exception('User not found');

        final user = UserModel.fromFirestore(doc);
        final oldRating = user.rating;
        final count = user.ratingCount;

        final newCount = count + 1;
        final newRating = ((oldRating * count) + rating) / newCount;

        transaction.update(userRef, {
          'rating': newRating,
          'ratingCount': newCount,
        });

        // Add detailed rating to subcollection
        final ratingRef = userRef.collection('ratings').doc();
        transaction.set(ratingRef, {
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to rate user: $e');
    }
  }

  // Get all riders (for admin/matching)
  Future<List<UserModel>> getAvailableRiders({
    required double pickupLat,
    required double pickupLng,
    double maxRadius = 10.0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isOnline', isEqualTo: true)
          .get();

      final riders =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Filter by distance from pickup location
      return riders.where((rider) {
        if (rider.lastLocation == null) return false;

        final riderLat = rider.lastLocation!['latitude'] as double;
        final riderLng = rider.lastLocation!['longitude'] as double;

        final distance =
            _calculateDistance(pickupLat, pickupLng, riderLat, riderLng);
        return distance <= maxRadius;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get riders: $e');
    }
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
}
