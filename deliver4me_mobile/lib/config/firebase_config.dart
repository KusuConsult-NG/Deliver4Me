class FirebaseConfig {
  // Firebase configuration
  // Note: Users need to add their Firebase config files:
  // - iOS: ios/Runner/GoogleService-Info.plist
  // - Android: android/app/google-services.json

  // Paystack Public Key
  static const String paystackPublicKey =
      'pk_test_3e87802dae281fbeb004f2b0f741a6e662aba103';

  // App Configuration
  static const String appName = 'Deliver4Me';
  static const bool isDevelopment = true;

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String transactionsCollection = 'transactions';
  static const String notificationsCollection = 'notifications';
}
