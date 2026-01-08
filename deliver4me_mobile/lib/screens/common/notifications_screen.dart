import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Notifications
    final notifications = [
      {
        'title': 'Welcome to Deliver4Me!',
        'body': 'Thanks for joining. Start sending or delivering today.',
        'time': '2 days ago',
        'isRead': true,
      },
      {
        'title': 'New Update Available',
        'body': 'Check out the new features we just added.',
        'time': '1 week ago',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] as bool;

                return Card(
                  color: isRead
                      ? Colors.white
                      : const Color(0xFF135BEC).withValues(alpha: 0.05),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF135BEC).withValues(alpha: 0.1),
                      child: const Icon(Icons.notifications,
                          color: Color(0xFF135BEC)),
                    ),
                    title: Text(
                      notification['title'] as String,
                      style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification['body'] as String),
                        const SizedBox(height: 8),
                        Text(
                          notification['time'] as String,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
