import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:intl/intl.dart';

class RiderHistoryScreen extends ConsumerWidget {
  const RiderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('riderId', isEqualTo: user.id)
                .where('status', isEqualTo: 'delivered') // Only show completed
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final orders =
                  docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No completed jobs yet'),
                    ],
                  ),
                );
              }

              // Calculate Earnings
              final totalEarnings = orders.fold(0.0, (acc, order) {
                // If riderEarnings field exists, use it. Else calculate 90% of price
                return acc +
                    (order.riderEarnings > 0
                        ? order.riderEarnings
                        : order.price * 0.9);
              });

              return Column(
                children: [
                  // Earnings Summary
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${orders.length} Completed Jobs',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // History List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final earnings = order.riderEarnings > 0
                            ? order.riderEarnings
                            : order.price * 0.9;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1C2433), // Darker card
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle,
                                  color: Colors.green),
                            ),
                            title: Text(
                              order.parcelDescription,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                    DateFormat('MMM d, y • h:mm a')
                                        .format(order.createdAt),
                                    style: TextStyle(
                                        color: Colors.grey[400], fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order.dropoff.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              '₦${earnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              // Maybe show details later
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
