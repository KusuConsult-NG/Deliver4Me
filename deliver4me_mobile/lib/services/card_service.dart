import 'package:cloud_firestore/cloud_firestore.dart';

class CardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save masked card metadata
  Future<void> saveCard({
    required String userId,
    required String cardNumber,
    required String expiryDate,
    required String cardHolder,
    bool isDefault = false,
  }) async {
    try {
      final maskedNumber =
          '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}';
      final cardType = _determineCardType(cardNumber);

      final cardData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'maskedNumber': maskedNumber,
        'expiryDate': expiryDate,
        'cardHolder': cardHolder,
        'cardType': cardType,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update({
        'savedCards': FieldValue.arrayUnion([cardData]),
      });
    } catch (e) {
      throw Exception('Failed to save card: $e');
    }
  }

  // Delete a card
  Future<void> deleteCard(String userId, Map<String, dynamic> cardData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'savedCards': FieldValue.arrayRemove([cardData]),
      });
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  String _determineCardType(String number) {
    if (number.startsWith('4')) return 'VISA';
    if (number.startsWith('5')) return 'MASTERCARD';
    return 'CARD';
  }
}
