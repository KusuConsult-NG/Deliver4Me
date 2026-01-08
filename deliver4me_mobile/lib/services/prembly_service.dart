import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PremblyService {
  static const String _baseUrl = 'https://api.prembly.com';
  static const String _apiKey = 'live_sk_22bb78f4aa5c4e51ba5f072147fda698';

  // Verification types: 'bvn', 'nin', 'pvc', 'drivers_license'
  Future<Map<String, dynamic>> verifyIdentity({
    required String type,
    required String number,
    Map<String, String>? additionalData,
  }) async {
    final endpoint = _getEndpoint(type);
    final url = Uri.parse('$_baseUrl$endpoint');

    final body = {
      'number': number,
      ...?additionalData,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Verification failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Prembly Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to verification service',
      };
    }
  }

  String _getEndpoint(String type) {
    switch (type.toLowerCase()) {
      case 'bvn':
        return '/identitypass/verification/bvn';
      case 'nin':
        return '/identitypass/verification/nin';
      case 'address':
        return '/identitypass/verification/address';
      default:
        throw Exception('Unsupported verification type: $type');
    }
  }

  // Address verification specifically might have a different structure
  Future<Map<String, dynamic>> verifyAddress({
    required String address,
    required String city,
    required String state,
    required String firstName,
    required String lastName,
  }) async {
    final url = Uri.parse('$_baseUrl/identitypass/verification/address');

    final body = {
      'address': address,
      'city': city,
      'state': state,
      'first_name': firstName,
      'last_name': lastName,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Prembly Address Error: $e');
      return {'status': false, 'message': 'Address verification failed'};
    }
  }
}
