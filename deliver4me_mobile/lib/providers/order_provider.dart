import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';

final orderService = OrderService();

// Stream provider for a single order by ID
final orderStreamProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return orderService.streamOrder(orderId);
});

// Stream provider for available jobs
final availableJobsProvider = StreamProvider<List<OrderModel>>((ref) {
  return orderService.streamAvailableJobs();
});

// Stream provider for user orders (sender)
final userOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  return orderService.streamUserOrders(userId);
});

// Stream provider for rider orders
final riderOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, riderId) {
  return orderService.streamRiderOrders(riderId);
});
