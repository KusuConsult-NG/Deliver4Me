import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';

// Service provider
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// User orders provider (for senders)
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(orderServiceProvider).streamUserOrders(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Rider orders provider
final riderOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(orderServiceProvider).streamRiderOrders(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Available jobs provider (for riders)
final availableJobsProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).streamAvailableJobs();
});

// Single order provider
final orderProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).streamOrder(orderId);
});
