import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { sender, rider }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final double walletBalance;
  final double rating;
  final int totalDeliveries;
  final DateTime createdAt;

  // Rider-specific fields
  final String? vehicleType;
  final double? deliveryRadius;
  final List<String>? activeZones;
  final bool? isOnline;
  final bool? isVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.role,
    this.walletBalance = 0.0,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    required this.createdAt,
    this.vehicleType,
    this.deliveryRadius,
    this.activeZones,
    this.isOnline = false,
    this.isVerified = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: data['role'] == 'rider' ? UserRole.rider : UserRole.sender,
      walletBalance: (data['walletBalance'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      vehicleType: data['vehicleType'],
      deliveryRadius: data['deliveryRadius']?.toDouble(),
      activeZones: data['activeZones'] != null
          ? List<String>.from(data['activeZones'])
          : null,
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role == UserRole.rider ? 'rider' : 'sender',
      'walletBalance': walletBalance,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'createdAt': Timestamp.fromDate(createdAt),
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (deliveryRadius != null) 'deliveryRadius': deliveryRadius,
      if (activeZones != null) 'activeZones': activeZones,
      if (isOnline != null) 'isOnline': isOnline,
      if (isVerified != null) 'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    UserRole? role,
    double? walletBalance,
    double? rating,
    int? totalDeliveries,
    DateTime? createdAt,
    String? vehicleType,
    double? deliveryRadius,
    List<String>? activeZones,
    bool? isOnline,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      vehicleType: vehicleType ?? this.vehicleType,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      activeZones: activeZones ?? this.activeZones,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
