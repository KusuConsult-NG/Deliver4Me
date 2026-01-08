import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/sender/parcel_tracker_screen.dart';
import 'package:deliver4me_mobile/screens/profile_screen.dart';
import 'package:deliver4me_mobile/screens/sender/sender_wallet_screen.dart';
import 'package:deliver4me_mobile/screens/sender/sender_history_screen.dart';
import 'package:deliver4me_mobile/screens/common/notifications_screen.dart';
import 'package:deliver4me_mobile/screens/common/help_support_screen.dart';
// import 'package:deliver4me_mobile/services/auth_service.dart'; // Unused

class SenderHomeScreen extends ConsumerWidget {
  const SenderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return PopScope(
        canPop: false, // Prevent default pop
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // Optional: Show valid exit confirmation or minimize
          // SystemNavigator.pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Deliver4Me'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user?.name ?? 'User'),
                  accountEmail: Text(user?.email ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24, color: Color(0xFF135BEC)),
                          )
                        : null,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF135BEC)),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('My Wallet'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SenderWalletScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('My Deliveries'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SenderHistoryScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Re-trigger streams if needed
              return Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Text(
                    'Hello, ${user?.name ?? 'User'}! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Where are we sending today?',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Card
                  _buildQuickActionCard(context),

                  const SizedBox(height: 32),

                  // Wallet & Active Orders Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SenderWalletScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: _buildInfoBox(
                            'Wallet Balance',
                            '₦${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                            Icons.account_balance_wallet,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoBox(
                          'Total Send',
                          '${user?.totalDeliveries ?? 0}',
                          Icons.local_shipping,
                          const Color(0xFF135BEC),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Active Orders Section
                  const Text(
                    'Active Deliveries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActiveOrdersList(context, ref, user?.id),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF135BEC), Color(0xFF0A3489)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Delivery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send parcels across the city with real-time tracking.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-delivery');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF135BEC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Sending',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2433),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(
      BuildContext context, WidgetRef ref, String? userId) {
    if (userId == null) return const SizedBox.shrink();

    final ordersStream = ref.watch(userOrdersProvider(userId));

    return ordersStream.when(
      data: (orders) {
        final activeOrders = orders
            .where((o) =>
                o.status != OrderStatus.delivered &&
                o.status != OrderStatus.cancelled)
            .toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  const Text(
                    'No active deliveries',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return _buildOrderTile(context, order);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildOrderTile(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1C2433),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParcelTrackerScreen(orderId: order.id),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_shipping, color: Color(0xFF135BEC)),
        ),
        title: Text(
          order.parcelDescription,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Status: ${order.status.toString().split('.').last}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
