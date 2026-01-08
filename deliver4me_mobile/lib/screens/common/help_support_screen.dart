import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildExpansion('How do I track my parcel?',
                'Go to the "My Deliveries" section and tap on the active order to see real-time tracking.'),
            _buildExpansion('How do I become a rider?',
                'Sign up as a user, then go to Profile > Become a Rider and complete the KYC verification.'),
            _buildExpansion('What payment methods are supported?',
                'We support all major credit/debit cards via Paystack, as well as wallet transfers.'),
            const SizedBox(height: 32),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF135BEC)),
              title: const Text('Email Support'),
              subtitle: const Text('support@deliver4me.ng'),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@deliver4me.ng',
                  query: 'subject=Support Request',
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF135BEC)),
              title: const Text('Call Us'),
              subtitle: const Text('+234 800 123 4567'),
              onTap: () async {
                final Uri phoneLaunchUri = Uri(
                  scheme: 'tel',
                  path: '+2348001234567',
                );
                if (await canLaunchUrl(phoneLaunchUri)) {
                  await launchUrl(phoneLaunchUri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp Chat'),
              subtitle: const Text('Chat with a support agent'),
              onTap: () async {
                // Open WhatsApp
                final Uri waUri = Uri.parse('https://wa.me/2348001234567');
                if (await canLaunchUrl(waUri)) {
                  await launchUrl(waUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: const Text('Report an Issue'),
              subtitle: const Text('Having trouble with an order?'),
              onTap: () {
                // Navigate to report screen or show dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Report Issue'),
                    content: const Text(
                        'Please email us at support@deliver4me.ng with your Order ID and details of the issue.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansion(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content),
          ),
        ],
      ),
    );
  }
}
