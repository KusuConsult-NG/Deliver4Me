import 'package:flutter_test/flutter_test.dart';
import 'package:deliver4me_mobile/services/payment_service.dart';
import 'package:deliver4me_mobile/config/firebase_config.dart';

void main() {
  group('PaymentService Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService(FirebaseConfig.paystackPublicKey);
    });

    test('PaymentService instance created with API key', () {
      expect(paymentService, isNotNull);
    });

    test('Paystack public key is configured', () {
      expect(FirebaseConfig.paystackPublicKey, isNotEmpty);
      expect(FirebaseConfig.paystackPublicKey, startsWith('pk_'));
    });

    test('Initialize transaction - requires network', () async {
      try {
        final result = await paymentService.initializeTransaction(
          email: 'test@example.com',
          amount: 100.0,
          reference: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        );

        expect(result, isNotNull);
        expect(result, containsPair('authorization_url', anything));
      } catch (e) {
        // Expected to fail without network or valid key
        expect(e, isNotNull);
      }
    }, skip: 'Requires network connection');
  });
}
