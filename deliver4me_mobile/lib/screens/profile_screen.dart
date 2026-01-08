import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/screens/sender/sender_history_screen.dart';
import 'package:deliver4me_mobile/screens/sender/sender_wallet_screen.dart';
import 'package:deliver4me_mobile/screens/rider/rider_reviews_screen.dart';
import 'package:deliver4me_mobile/screens/rider/rider_preferences_screen.dart';
import 'package:deliver4me_mobile/screens/common/notifications_screen.dart';
import 'package:deliver4me_mobile/screens/common/help_support_screen.dart';
import 'package:deliver4me_mobile/models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:deliver4me_mobile/services/storage_service.dart';
import 'package:deliver4me_mobile/services/user_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF135BEC),
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 75,
                          );

                          if (pickedFile != null && context.mounted) {
                            // Show loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Uploading photo...')),
                            );

                            try {
                              final storageService = StorageService();
                              final userService = UserService();

                              // 1. Upload to Storage
                              final downloadUrl =
                                  await storageService.uploadProfilePhoto(
                                user.id,
                                File(pickedFile.path),
                              );

                              // 2. Update Firestore
                              await userService.updateProfilePhoto(
                                  user.id, downloadUrl);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile photo updated!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Upload failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Color(0xFF135BEC)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(user.role.name.toUpperCase()),
                  backgroundColor:
                      const Color(0xFF135BEC).withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                      color: Color(0xFF135BEC), fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 32),

                // Profile Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // Dark card for dark theme
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem(
                          Icons.phone, 'Phone', user.phone ?? 'Not set'),
                      const Divider(),
                      _buildProfileItem(Icons.location_on, 'Location',
                          '${user.city ?? ''}, ${user.country ?? ''}'),
                      const Divider(),
                      _buildProfileItem(Icons.wallet, 'Wallet Balance',
                          '₦${user.walletBalance.toStringAsFixed(2)}'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Menu Options
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (user.role == UserRole.sender) ...[
                        _buildMenuOption(
                            context,
                            'Wallet & Transactions',
                            Icons.account_balance_wallet,
                            const SenderWalletScreen()),
                        const Divider(height: 1),
                        _buildMenuOption(context, 'My Deliveries',
                            Icons.history, const SenderHistoryScreen()),
                      ],
                      if (user.role == UserRole.rider) ...[
                        _buildMenuOption(context, 'Delivery Preferences',
                            Icons.tune, const RiderPreferencesScreen()),
                        const Divider(height: 1),
                        _buildMenuOption(context, 'My Reviews', Icons.star,
                            const RiderReviewsScreen()),
                      ],
                      const Divider(height: 1),
                      _buildMenuOption(context, 'Notifications',
                          Icons.notifications, const NotificationsScreen()),
                      const Divider(height: 1),
                      _buildMenuOption(context, 'Help & Support',
                          Icons.help_outline, const HelpSupportScreen()),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50], // Light red background
                      foregroundColor: Colors.red, // Red text/icon
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
      BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
