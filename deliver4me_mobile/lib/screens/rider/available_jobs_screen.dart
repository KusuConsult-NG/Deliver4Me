import 'package:flutter/material.dart';

class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF135BEC),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image:
                                NetworkImage('https://placeholder.pics/svg/40'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME BACK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Text(
                              'Alex Mitchell',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF324467),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF135BEC),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '\$124.00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF324467)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rss_feed,
                            color: Color(0xFF135BEC),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are Online',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Receiving job alerts',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: true,
                          onChanged: (value) {},
                          activeColor: const Color(0xFF135BEC),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('Nearest', Icons.near_me, true),
                  _buildFilterChip('Highest Pay', Icons.payments, false),
                  _buildFilterChip('Short Distance', Icons.straight, false),
                  _buildFilterChip('Small Cargo', Icons.inventory_2, false),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Job Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildJobCard(
                    price: '\$24.00',
                    distance: '4.2 km • 15 mins',
                    pickup: '123 Main St, Downtown',
                    dropoff: '450 Highland Ave, Suburb',
                    badges: ['Small Parcel', 'Verified'],
                  ),
                  const SizedBox(height: 16),
                  _buildJobCard(
                    price: '\$8.50',
                    distance: '1.1 km • 5 mins',
                    pickup: 'Tech Park, Building B',
                    dropoff: '88 Lowland Rd',
                    badges: ['Urgent'],
                    isUrgent: true,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF92A4C9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scanning for new jobs...',
                          style: TextStyle(
                            color: Color(0xFF92A4C9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF135BEC) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF135BEC) : const Color(0xFF324467),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : const Color(0xFF92A4C9),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF92A4C9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required String price,
    required String distance,
    required String pickup,
    required String dropoff,
    required List<String> badges,
    bool isUrgent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF192233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF324467)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Header
          Container(
            height: 128,
            decoration: const BoxDecoration(
              color: Color(0xFF2A3A4F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.social_distance,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF135BEC),
                              width: 3,
                            ),
                            color: const Color(0xFF192233),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF135BEC).withValues(alpha: 0.5),
                                const Color(0xFF92A4C9).withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF92A4C9),
                              width: 3,
                            ),
                            color: const Color(0xFF192233),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICK-UP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            pickup,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DROP-OFF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            dropoff,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[800], height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ...badges.map((badge) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : const Color(0xFF232F48),
                            borderRadius: BorderRadius.circular(4),
                            border: isUrgent
                                ? Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.2),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              if (isUrgent)
                                const Icon(
                                  Icons.bolt,
                                  color: Color(0xFFEF4444),
                                  size: 14,
                                ),
                              if (!isUrgent)
                                const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF92A4C9),
                                  size: 14,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isUrgent
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF92A4C9),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Spacer(),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135BEC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Row(
                          children: [
                            Text('Accept'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF192233).withValues(alpha: 0.9),
        border: const Border(
          top: BorderSide(color: Color(0xFF324467)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.work, 'Jobs', true),
              _buildNavItem(Icons.local_shipping, 'Active', false, badge: '1'),
              _buildNavItem(Icons.account_balance_wallet, 'Wallet', false),
              _buildNavItem(Icons.settings, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive,
      {String? badge}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF135BEC) : const Color(0xFF92A4C9),
              size: 24,
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF135BEC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFF135BEC) : const Color(0xFF92A4C9),
          ),
        ),
      ],
    );
  }
}
