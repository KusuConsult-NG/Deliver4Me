import 'package:flutter/material.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101622),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('KYC Verification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bars
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? const Color(0xFF135BEC)
                          : const Color(0xFF324467),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Boost your credibility',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete verification to unlock premium jobs and higher earnings.',
              style: TextStyle(
                color: Color(0xFF92A4C9),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            _buildVerificationStep(
              icon: Icons.badge,
              title: 'Verify ID Document',
              subtitle:
                  'Upload government-issued ID (Passport, Driver\'s License)',
              isComplete: false,
              hasAction: true,
            ),

            const SizedBox(height: 16),

            _buildVerificationStep(
              icon: Icons.camera_alt,
              title: 'Selfie Verification',
              subtitle: 'Take a quick selfie to match with your ID',
              isComplete: false,
              hasAction: false,
            ),

            const SizedBox(height: 16),

            _buildVerificationStep(
              icon: Icons.check_circle,
              title: 'Background Check',
              subtitle: 'Automated verification (takes 1-2 business days)',
              isComplete: false,
              hasAction: false,
            ),

            const SizedBox(height: 32),

            // Benefits Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF135BEC).withValues(alpha: 0.1),
                    const Color(0xFF0A3489).withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Color(0xFF135BEC),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Verified Rider Benefits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem('Access to premium high-value deliveries'),
                  _buildBenefitItem('Priority job matching'),
                  _buildBenefitItem('Earn up to 30% more'),
                  _buildBenefitItem('Verified badge on your profile'),
                  _buildBenefitItem('Faster payouts & withdrawals'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2536),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF324467).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF92A4C9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your data is secure',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All documents are encrypted and handled according to privacy regulations. We never share your data with third parties.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file),
                      SizedBox(width: 12),
                      Text('Upload ID Document'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'I\'ll do this later',
                  style: TextStyle(
                    color: Color(0xFF92A4C9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool hasAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF192233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAction
              ? const Color(0xFF135BEC).withValues(alpha: 0.5)
              : const Color(0xFF324467),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasAction
                  ? const Color(0xFF135BEC).withValues(alpha: 0.1)
                  : const Color(0xFF324467).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  hasAction ? const Color(0xFF135BEC) : const Color(0xFF92A4C9),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF92A4C9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 24,
            )
          else if (hasAction)
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF135BEC),
              size: 18,
            )
          else
            const Icon(
              Icons.lock,
              color: Color(0xFF324467),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF92A4C9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
