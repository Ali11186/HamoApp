import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';

/// Client-side unsigned image upload for product and chat images.
/// Never put the Cloudinary API secret in a mobile app.
class CloudinaryUploadService {
  static const String cloudName = 'wtp0e4bv';
  static const String uploadPreset = 'mohammed_store';

  Future<String> uploadImage(File image, {required String folder}) async {
    return uploadFile(image, folder: folder, resourceType: 'image');
  }

  Future<String> uploadFile(File file,
      {required String folder, String resourceType = 'auto'}) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['secure_url'] == null) {
        throw StorageException(
            message:
                data['error']?['message']?.toString() ?? 'تعذر رفع الصورة');
      }
      return data['secure_url'] as String;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(message: 'تعذر رفع الصورة: $e');
    }
  }
}
