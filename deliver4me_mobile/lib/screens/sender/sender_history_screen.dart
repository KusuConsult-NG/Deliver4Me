import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/order_service.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/sender/parcel_tracker_screen.dart';

class SenderHistoryScreen extends ConsumerWidget {
  const SenderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final orderService = OrderService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderService.streamUserOrders(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No deliveries yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isCompleted = order.status == OrderStatus.delivered;
              final isCancelled = order.status == OrderStatus.cancelled;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isCancelled
                            ? Colors.red.withValues(alpha: 0.1)
                            : const Color(0xFF135BEC).withValues(alpha: 0.1)),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : (isCancelled ? Icons.close : Icons.local_shipping),
                      color: isCompleted
                          ? Colors.green
                          : (isCancelled
                              ? Colors.red
                              : const Color(0xFF135BEC)),
                    ),
                  ),
                  title: Text(order.parcelDescription),
                  subtitle: Text(_formatDate(order.createdAt)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${order.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCompleted
                              ? Colors.green
                              : (isCancelled ? Colors.red : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isCancelled) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ParcelTrackerScreen(orderId: order.id),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
