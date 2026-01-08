import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserRole { sender, rider }

enum KycTier { unverified, tier1, tier2, tier3 }

enum VehicleType {
  motorcycle,
  tricycle, // Keke NAPEP
  car,
  van
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final double walletBalance;
  final double rating;
  final int ratingCount;
  final int totalDeliveries;
  final DateTime createdAt;
  final KycTier kycTier;
  final double dailyDepositLimit;
  final double dailyWithdrawalLimit;
  final double maxBalanceLimit;
  final double currentDailyDeposit;
  final DateTime? lastDepositDate;

  // Rider-specific fields
  final String? vehicleType;
  final double? deliveryRadius;
  final List<String>? activeZones;
  final bool? isOnline;
  final bool? isVerified;
  final Map<String, dynamic>? lastLocation;

  // KYC & Card fields
  final String kycStatus; // 'unverified', 'pending', 'verified', 'rejected'
  final List<String> kycDocuments;
  final List<Map<String, dynamic>> savedCards;

  // Demographics (New)
  final String? country;
  final String? state;
  final String? city;
  final String? gender;
  final int? age;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.role,
    this.walletBalance = 0.0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.totalDeliveries = 0,
    required this.createdAt,
    this.vehicleType,
    this.deliveryRadius,
    this.activeZones,
    this.isOnline = false,
    this.isVerified = false,
    this.lastLocation,
    this.kycStatus = 'unverified',
    this.kycDocuments = const [],
    this.savedCards = const [],
    this.kycTier = KycTier.unverified,
    this.dailyDepositLimit = 10000.0,
    this.dailyWithdrawalLimit = 10000.0,
    this.maxBalanceLimit = 50000.0,
    this.currentDailyDeposit = 0.0,
    this.lastDepositDate,
    this.country,
    this.state,
    this.city,
    this.gender,
    this.age,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Helper for safe double parsing
      double parseDouble(dynamic value, double defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      // Safe KycTier parsing
      KycTier parseKycTier(dynamic value) {
        if (value == null) return KycTier.unverified;
        final str = value.toString();
        return KycTier.values.firstWhere(
          (e) {
            final shortName = e.toString().split('.').last;
            return shortName == str ||
                e.toString() == str ||
                shortName == str.trim();
          },
          orElse: () => KycTier.unverified,
        );
      }

      // Safe Date parsing
      DateTime parseDate(dynamic value) {
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return UserModel(
        id: doc.id,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        phone: data['phone'],
        photoUrl: data['photoUrl'],
        role: data['role'] == 'rider' ? UserRole.rider : UserRole.sender,
        walletBalance: parseDouble(data['walletBalance'], 0.0),
        rating: parseDouble(data['rating'], 0.0),
        ratingCount: data['ratingCount'] is int ? data['ratingCount'] : 0,
        totalDeliveries:
            data['totalDeliveries'] is int ? data['totalDeliveries'] : 0,
        createdAt: parseDate(data['createdAt']),
        vehicleType: data['vehicleType'],
        deliveryRadius: parseDouble(data['deliveryRadius'], 0.0),
        activeZones: data['activeZones'] != null
            ? List<String>.from(data['activeZones'])
            : null,
        isOnline: data['isOnline'] ?? false,
        isVerified: data['isVerified'] ?? false,
        lastLocation: data['lastLocation'] as Map<String, dynamic>?,
        kycStatus: data['kycStatus'] ?? 'unverified',
        kycDocuments: List<String>.from(data['kycDocuments'] ?? []),
        savedCards: List<Map<String, dynamic>>.from(data['savedCards'] ?? []),
        kycTier: parseKycTier(data['kycTier']),
        dailyDepositLimit: parseDouble(data['dailyDepositLimit'], 10000.0),
        dailyWithdrawalLimit:
            parseDouble(data['dailyWithdrawalLimit'], 10000.0),
        maxBalanceLimit: parseDouble(data['maxBalanceLimit'], 50000.0),
        currentDailyDeposit: parseDouble(data['currentDailyDeposit'], 0.0),
        lastDepositDate: data['lastDepositDate'] != null
            ? parseDate(data['lastDepositDate'])
            : null,
        country: data['country'],
        state: data['state'],
        city: data['city'],
        gender: data['gender'],
        age: data['age'] is int
            ? data['age']
            : (data['age'] is String ? int.tryParse(data['age']) : null),
      );
    } catch (e) {
      // Log the error (in a real app, use a logger)
      debugPrint('Error parsing UserModel: $e');
      // Return a basic fallback user to prevent app crash
      return UserModel(
        id: doc.id,
        email: '',
        name: 'Error User',
        role: UserRole.sender,
        createdAt: DateTime.now(),
      );
    }
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
      'ratingCount': ratingCount,
      'totalDeliveries': totalDeliveries,
      'createdAt': Timestamp.fromDate(createdAt),
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (deliveryRadius != null) 'deliveryRadius': deliveryRadius,
      if (activeZones != null) 'activeZones': activeZones,
      'isOnline': isOnline,
      'isVerified': isVerified,
      if (lastLocation != null) 'lastLocation': lastLocation,
      'kycStatus': kycStatus,
      'kycDocuments': kycDocuments,
      'savedCards': savedCards,
      'kycTier': kycTier.toString().split('.').last,
      'dailyDepositLimit': dailyDepositLimit,
      'dailyWithdrawalLimit': dailyWithdrawalLimit,
      'maxBalanceLimit': maxBalanceLimit,
      'currentDailyDeposit': currentDailyDeposit,
      'lastDepositDate':
          lastDepositDate != null ? Timestamp.fromDate(lastDepositDate!) : null,
      if (country != null) 'country': country,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
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
    int? ratingCount,
    int? totalDeliveries,
    DateTime? createdAt,
    String? vehicleType,
    double? deliveryRadius,
    List<String>? activeZones,
    bool? isOnline,
    bool? isVerified,
    Map<String, dynamic>? lastLocation,
    String? kycStatus,
    List<String>? kycDocuments,
    List<Map<String, dynamic>>? savedCards,
    KycTier? kycTier,
    double? dailyDepositLimit,
    double? dailyWithdrawalLimit,
    double? maxBalanceLimit,
    double? currentDailyDeposit,
    DateTime? lastDepositDate,
    String? country,
    String? state,
    String? city,
    String? gender,
    int? age,
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
      ratingCount: ratingCount ?? this.ratingCount,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      vehicleType: vehicleType ?? this.vehicleType,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      activeZones: activeZones ?? this.activeZones,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      lastLocation: lastLocation ?? this.lastLocation,
      kycStatus: kycStatus ?? this.kycStatus,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      savedCards: savedCards ?? this.savedCards,
      kycTier: kycTier ?? this.kycTier,
      dailyDepositLimit: dailyDepositLimit ?? this.dailyDepositLimit,
      dailyWithdrawalLimit: dailyWithdrawalLimit ?? this.dailyWithdrawalLimit,
      maxBalanceLimit: maxBalanceLimit ?? this.maxBalanceLimit,
      currentDailyDeposit: currentDailyDeposit ?? this.currentDailyDeposit,
      lastDepositDate: lastDepositDate ?? this.lastDepositDate,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }
}
