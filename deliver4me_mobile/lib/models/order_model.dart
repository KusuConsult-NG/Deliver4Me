import 'package:cloud_firestore/cloud_firestore.dart';
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
    return LocationData(
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
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
    return TimelineEvent(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
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
  final DateTime? estimatedArrival;

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
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      riderId: data['riderId'],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      pickup: LocationData.fromMap(data['pickup'] ?? {}),
      dropoff: LocationData.fromMap(data['dropoff'] ?? {}),
      parcelDescription: data['parcelDescription'] ?? '',
      weightCategory: data['weightCategory'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? false,
      deliveryCode: data['deliveryCode'] ?? '',
      timeline: (data['timeline'] as List? ?? [])
          .map((e) => TimelineEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      pickedUpAt: data['pickedUpAt'] != null
          ? (data['pickedUpAt'] as Timestamp).toDate()
          : null,
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      notes: data['notes'] ?? '',
      riderName: data['riderName'],
      riderPhone: data['riderPhone'],
      riderLocation: data['riderLocation'] as Map<String, dynamic>?,
      estimatedArrival: data['estimatedArrival'] != null
          ? (data['estimatedArrival'] as Timestamp).toDate()
          : null,
    );
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
    );
  }
}
