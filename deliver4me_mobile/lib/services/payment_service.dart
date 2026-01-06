import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  final String _paystackPublicKey;
  final String _baseUrl = 'https://api.paystack.co';

  PaymentService(this._paystackPublicKey);

  // Initialize transaction
  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amount,
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_paystackPublicKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'amount': (amount * 100).toInt(), // Convert to kobo
          'reference': reference,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to initialize transaction');
      }
    } catch (e) {
      throw Exception('Payment initialization failed: $e');
    }
  }

  // Verify transaction
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_paystackPublicKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': data['data']['status'] == 'success' ? 'success' : 'failed',
          'data': data['data']
        };
      }
      return {'status': 'failed', 'message': 'Verification request failed'};
    } catch (e) {
      return {'status': 'failed', 'message': e.toString()};
    }
  }

  // Create transfer recipient (for withdrawals)
  Future<String?> createTransferRecipient({
    required String accountNumber,
    required String bankCode,
    required String accountName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transferrecipient'),
        headers: {
          'Authorization': 'Bearer $_paystackPublicKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': 'nuban',
          'name': accountName,
          'account_number': accountNumber,
          'bank_code': bankCode,
          'currency': 'NGN',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['recipient_code'];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create recipient: $e');
    }
  }

  // Get Nigerian banks list
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bank'),
        headers: {
          'Authorization': 'Bearer $_paystackPublicKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
