import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/user_model.dart';

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

  // Update wallet balance
  Future<void> updateWalletBalance(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
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

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      // TODO: Filter by distance from pickup location
    } catch (e) {
      throw Exception('Failed to get riders: $e');
    }
  }
}
