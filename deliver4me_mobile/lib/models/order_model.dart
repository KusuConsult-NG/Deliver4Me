import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum OrderStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled
}

class LocationData {
  final String address;
  final double latitude;
  final double longitude;

  LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return LocationData(
      address: map['address'] ?? '',
      latitude: safeDouble(map['latitude']),
      longitude: safeDouble(map['longitude']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
}

class TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isComplete;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isComplete,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    DateTime safeDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TimelineEvent(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: safeDate(map['timestamp']),
      isComplete: map['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'isComplete': isComplete,
    };
  }
}

class OrderModel {
  final String id;
  final String senderId;
  final String? riderId;
  final OrderStatus status;
  final LocationData pickup;
  final LocationData dropoff;
  final String parcelDescription;
  final String weightCategory;
  final double price;
  final String paymentMethod;
  final bool paymentStatus;
  final String deliveryCode;
  final List<TimelineEvent> timeline;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? pickedUpAt;
  final String recipientName;
  final String recipientPhone;
  final String notes;
  final String? riderName;
  final String? riderPhone;
  final Map<String, dynamic>? riderLocation;
  final bool isUrgent;
  final bool isASAP;
  final DateTime? estimatedArrival;

  // Payment & Commission Fields
  final double platformCommission; // 10% of price
  final double riderEarnings; // price - platformCommission
  final bool fundsReleasedToRider; // Auto-release on delivery

  // Waiting Time Tracking
  final DateTime? arrivedAtPickupTime;
  final DateTime? arrivedAtDropoffTime;
  final double waitingCharges; // ₦100/min from 2nd minute

  OrderModel({
    required this.id,
    required this.senderId,
    this.riderId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.parcelDescription,
    required this.weightCategory,
    required this.price,
    required this.paymentMethod,
    this.paymentStatus = false,
    required this.deliveryCode,
    required this.timeline,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    this.pickedUpAt,
    required this.recipientName,
    required this.recipientPhone,
    this.notes = '',
    this.riderName,
    this.riderPhone,
    this.riderLocation,
    this.estimatedArrival,
    this.isUrgent = false,
    this.isASAP = false,
    this.platformCommission = 0.0,
    this.riderEarnings = 0.0,
    this.fundsReleasedToRider = false,
    this.arrivedAtPickupTime,
    this.arrivedAtDropoffTime,
    this.waitingCharges = 0.0,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
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

      // Safe Date parsing
      DateTime parseDate(dynamic value) {
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      // Safe Date parsing (Nullable)
      DateTime? parseDateNullable(dynamic value) {
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value);
        return null;
      }

      // Safe Timeline parsing
      List<TimelineEvent> parseTimeline(dynamic value) {
        if (value is! List) return [];
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return TimelineEvent(
              title: e['title'] ?? '',
              description: e['description'] ?? '',
              timestamp: parseDate(e['timestamp']),
              isComplete: e['isComplete'] ?? false,
            );
          }
          return TimelineEvent(
              title: 'Unknown',
              description: '',
              timestamp: DateTime.now(),
              isComplete: false);
        }).toList();
      }

      return OrderModel(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        riderId: data['riderId'],
        status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
          orElse: () => OrderStatus.pending,
        ),
        pickup: LocationData.fromMap(data['pickup'] is Map<String, dynamic>
            ? data['pickup']
            : {'address': 'Unknown', 'latitude': 0, 'longitude': 0}),
        dropoff: LocationData.fromMap(data['dropoff'] is Map<String, dynamic>
            ? data['dropoff']
            : {'address': 'Unknown', 'latitude': 0, 'longitude': 0}),
        parcelDescription: data['parcelDescription'] ?? '',
        weightCategory: data['weightCategory'] ?? '',
        price: parseDouble(data['price'], 0.0),
        paymentMethod: data['paymentMethod'] ?? 'Cash',
        paymentStatus: data['paymentStatus'] ?? false,
        deliveryCode: data['deliveryCode'] ?? '',
        timeline: parseTimeline(data['timeline']),
        createdAt: parseDate(data['createdAt']),
        acceptedAt: parseDateNullable(data['acceptedAt']),
        deliveredAt: parseDateNullable(data['deliveredAt']),
        pickedUpAt: parseDateNullable(data['pickedUpAt']),
        recipientName: data['recipientName'] ?? '',
        recipientPhone: data['recipientPhone'] ?? '',
        notes: data['notes'] ?? '',
        riderName: data['riderName'],
        riderPhone: data['riderPhone'],
        riderLocation: data['riderLocation'] as Map<String, dynamic>?,
        estimatedArrival: parseDateNullable(data['estimatedArrival']),
        isUrgent: data['isUrgent'] ?? false,
        isASAP: data['isASAP'] ?? false,
        platformCommission: parseDouble(data['platformCommission'], 0.0),
        riderEarnings: parseDouble(data['riderEarnings'], 0.0),
        fundsReleasedToRider: data['fundsReleasedToRider'] ?? false,
        arrivedAtPickupTime: parseDateNullable(data['arrivedAtPickupTime']),
        arrivedAtDropoffTime: parseDateNullable(data['arrivedAtDropoffTime']),
        waitingCharges: parseDouble(data['waitingCharges'], 0.0),
      );
    } catch (e) {
      debugPrint('Error parsing OrderModel: $e');
      // Return a safe fallback to prevent crash
      return OrderModel(
        id: doc.id,
        senderId: '',
        status: OrderStatus.pending,
        pickup: LocationData(address: 'Error', latitude: 0, longitude: 0),
        dropoff: LocationData(address: 'Error', latitude: 0, longitude: 0),
        parcelDescription: 'Error loading order',
        weightCategory: '',
        price: 0,
        paymentMethod: '',
        deliveryCode: '',
        timeline: [],
        createdAt: DateTime.now(),
        recipientName: '',
        recipientPhone: '',
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'riderId': riderId,
      'status': status.toString().split('.').last,
      'pickup': pickup.toMap(),
      'dropoff': dropoff.toMap(),
      'parcelDescription': parcelDescription,
      'weightCategory': weightCategory,
      'price': price,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryCode': deliveryCode,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (pickedUpAt != null) 'pickedUpAt': Timestamp.fromDate(pickedUpAt!),
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'notes': notes,
      if (riderName != null) 'riderName': riderName,
      if (riderPhone != null) 'riderPhone': riderPhone,
      if (riderLocation != null) 'riderLocation': riderLocation,
      if (estimatedArrival != null)
        'estimatedArrival': Timestamp.fromDate(estimatedArrival!),
      'isUrgent': isUrgent,
      'isASAP': isASAP,
      'platformCommission': platformCommission,
      'riderEarnings': riderEarnings,
      'fundsReleasedToRider': fundsReleasedToRider,
      if (arrivedAtPickupTime != null)
        'arrivedAtPickupTime': Timestamp.fromDate(arrivedAtPickupTime!),
      if (arrivedAtDropoffTime != null)
        'arrivedAtDropoffTime': Timestamp.fromDate(arrivedAtDropoffTime!),
      'waitingCharges': waitingCharges,
    };
  }

  OrderModel copyWith({
    String? id,
    String? senderId,
    String? riderId,
    OrderStatus? status,
    LocationData? pickup,
    LocationData? dropoff,
    String? parcelDescription,
    String? weightCategory,
    double? price,
    String? paymentMethod,
    bool? paymentStatus,
    String? deliveryCode,
    List<TimelineEvent>? timeline,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? deliveredAt,
    DateTime? pickedUpAt,
    String? recipientName,
    String? recipientPhone,
    String? notes,
    String? riderName,
    String? riderPhone,
    Map<String, dynamic>? riderLocation,
    DateTime? estimatedArrival,
    bool? isUrgent,
    bool? isASAP,
  }) {
    return OrderModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      parcelDescription: parcelDescription ?? this.parcelDescription,
      weightCategory: weightCategory ?? this.weightCategory,
      price: price ?? this.price,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryCode: deliveryCode ?? this.deliveryCode,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      notes: notes ?? this.notes,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderLocation: riderLocation ?? this.riderLocation,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      isUrgent: isUrgent ?? this.isUrgent,
      isASAP: isASAP ?? this.isASAP,
    );
  }
}
