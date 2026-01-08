import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile photo
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putFile(imageFile, metadata);

      // Wait a moment for consistency
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload not successful: ${uploadTask.state}');
      }
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upload parcel photo
  Future<String> uploadParcelPhoto(String orderId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('parcel_photos/$orderId/$timestamp.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload parcel photo: $e');
    }
  }

  // Upload KYC documents
  Future<String> uploadKYCDocument(
    String userId,
    String documentType,
    File imageFile,
  ) async {
    try {
      final ref =
          _storage.ref().child('kyc_documents/$userId/$documentType.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload KYC document: $e');
    }
  }

  // Delete file
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
