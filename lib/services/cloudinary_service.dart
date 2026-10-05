import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'ddxsov37g';
  static const String uploadPreset = 'VWC INC';

  static Future<Map<String, String>?> uploadContract({
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;

      if (!kIsWeb && file != null && await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (bytes != null && bytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename ?? 'contract_document',
        ));
      } else {
        debugPrint('Cloudinary Error: No valid file or bytes provided for upload.');
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          return {
            'secure_url': data['secure_url']?.toString() ?? '',
            'url': data['url']?.toString() ?? '',
            'public_id': data['public_id']?.toString() ?? '',
          };
        }
      } else {
        debugPrint('Cloudinary Server Error [${response.statusCode}]:${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary contract upload exception: $e');
      return null;
    }
  }

  static Future<String?> uploadImage({
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;

      if (!kIsWeb && file != null && await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (bytes != null && bytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename ?? 'uploaded_image',
        ));
      } else {
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return decoded['secure_url']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary image upload exception: $e');
      return null;
    }
  }

  static Future<bool> deleteContract(
      String publicId, [
        String? resourceType,
      ]) async {
    try {
      final type = resourceType ?? 'image';
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$type/destroy');
      final response = await http.post(uri, body: {
        'public_id': publicId,
        'upload_preset': uploadPreset,
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return decoded['result'] == 'ok';
        }
      }
      return false;
    } catch (e) {
      debugPrint('Cloudinary deletion exception: $e');
      return false;
    }
  }
}