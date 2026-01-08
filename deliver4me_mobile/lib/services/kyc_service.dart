import 'dart:async';
import 'package:deliver4me_mobile/models/user_model.dart';

class KycService {
  // Simulate Prembly API call
  Future<bool> verifyIdentity({
    required String number,
    required String type, // 'NIN' or 'BVN'
    required UserRole role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simple mock validation logic
    // In production, this would call Prembly's API
    if (number.length >= 11) {
      return true;
    }

    return false;
  }
}
