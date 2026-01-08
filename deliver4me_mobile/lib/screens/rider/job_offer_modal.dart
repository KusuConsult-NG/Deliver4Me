import 'package:flutter/material.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
import 'package:deliver4me_mobile/screens/rider/new_job_offer_screen.dart';

class JobOfferModal extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const JobOfferModal({
    super.key,
    required this.order,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header: Price & Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EARNINGS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Distance badge would require calculation passed in or simple "View Map"
              if (order.isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Route Visualizer
          _buildRouteItem(
            Icons.radio_button_checked,
            (const Color(0xFF135BEC)),
            'PICKUP',
            order.pickup.address,
            isFirst: true,
          ),
          _buildRouteItem(
            Icons.location_on,
            Colors.red,
            'DROP-OFF',
            order.dropoff.address,
            isLast: true,
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.parcelDescription,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline ?? () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'DECLINE',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept ??
                      () {
                        Navigator.pop(context); // Close modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NewJobOfferScreen(order: order),
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'VIEW DETAILS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRouteItem(
      IconData icon, Color color, String label, String address,
      {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: color, size: 20),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40, // Fixed height for visual consistency in modal
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
