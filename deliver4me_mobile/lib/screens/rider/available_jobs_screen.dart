import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/providers/order_provider.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/screens/rider/rider_preferences_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:deliver4me_mobile/screens/profile_screen.dart';
import 'package:deliver4me_mobile/screens/common/identity_verification_screen.dart';
import 'package:deliver4me_mobile/screens/rider/job_offer_modal.dart';

class AvailableJobsScreen extends ConsumerStatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  ConsumerState<AvailableJobsScreen> createState() =>
      _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends ConsumerState<AvailableJobsScreen> {
  final userService = UserService();
  bool isOnline = true;
  String filterType = 'all';
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user != null) {
      // Fetch full user model to check KYC status
      final userModel = await userService.getUserById(user.uid);

      if (userModel != null && !isOnline && userModel.kycStatus != 'verified') {
        // Enforce KYC check before going online
        if (!mounted) return;
        final verified = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
        );

        if (verified != true) return; // User cancelled or failed
      }

      setState(() => isOnline = !isOnline);

      await userService.updateRiderStatus(user.uid, isOnline);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isOnline ? 'You are now online' : 'You are now offline'),
            backgroundColor: isOnline ? Colors.green : Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user for preferences
    final availableJobsStream = ref.watch(availableJobsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiderPreferencesScreen(),
                ),
              );
            },
          ),
          // Online/Offline Toggle
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _toggleOnlineStatus,
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All Jobs', 'all'),
                _buildFilterChip('Nearby', 'nearby'),
                _buildFilterChip('High Pay', 'high_pay'),
                _buildFilterChip('Urgent', 'urgent'),
              ],
            ),
          ),

          // Jobs list
          Expanded(
            child: availableJobsStream.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isOnline
                              ? 'No jobs available right now'
                              : 'Go online to see available jobs',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Refresh handled by stream
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.where((job) {
                      final distance = _calculateDistance(job);
                      if (user?.deliveryRadius != null &&
                          distance > user!.deliveryRadius!) {
                        return false;
                      }

                      if (filterType == 'nearby') {
                        return distance <= 5.0;
                      } else if (filterType == 'high_pay') {
                        return job.price >= 30.0;
                      } else if (filterType == 'urgent') {
                        return job.isUrgent ||
                            job.isASAP ||
                            DateTime.now().difference(job.createdAt).inMinutes <
                                30;
                      }
                      return true;
                    }).length,
                    itemBuilder: (context, index) {
                      final filteredJobs = jobs.where((job) {
                        final distance = _calculateDistance(job);
                        if (user?.deliveryRadius != null &&
                            distance > user!.deliveryRadius!) {
                          return false; // Skip jobs outside preferred radius
                        }

                        if (filterType == 'nearby') {
                          return distance <= 5.0;
                        } else if (filterType == 'high_pay') {
                          return job.price >= 30.0;
                        } else if (filterType == 'urgent') {
                          return job.isUrgent ||
                              job.isASAP ||
                              DateTime.now()
                                      .difference(job.createdAt)
                                      .inMinutes <
                                  30;
                        }
                        return true;
                      }).toList();
                      return _buildJobCard(filteredJobs[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading jobs: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = filterType == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => filterType = value);
        },
        selectedColor: const Color(0xFF135BEC),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildJobCard(OrderModel order) {
    final distance = _calculateDistance(order); // Simplified
    final earnings = order.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => JobOfferModal(order: order),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (order.isUrgent)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            children: [
                              Icon(Icons.flash_on,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('URGENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      if (order.isASAP)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF135BEC),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            children: [
                              Icon(Icons.directions_run,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('ASAP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₦${earnings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Route
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF135BEC),
                        size: 16,
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.pickup.address,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          order.dropoff.address,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.parcelDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(order.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(OrderModel order) {
    if (currentPosition == null) return 0.0;

    final distanceInMeters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      order.pickup.latitude,
      order.pickup.longitude,
    );

    return distanceInMeters / 1000; // Convert to km
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
