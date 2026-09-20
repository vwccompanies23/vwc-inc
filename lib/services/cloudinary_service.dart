import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String _cloudName = 'ddxsov37g';
  static const String _uploadPreset = 'VWC INC';

  // Required for signed contract deletion API calls
  static const String _apiKey = 'YOUR_CLOUDINARY_API_KEY';
  static const String _apiSecret = 'YOUR_CLOUDINARY_API_SECRET';

  static final _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  /// Uploads an image file to Cloudinary and returns its public HTTPS URL.
  static Future<String?> uploadImage(File file) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'vwc_posts',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Uploads a contract file (PDF or Image) and returns URL + Public ID for tracking.
  static Future<Map<String, String>?> uploadContract(File file) async {
    try {
      final isPdf = file.path.toLowerCase().endsWith('.pdf');
      final resourceType = isPdf
          ? CloudinaryResourceType.Raw
          : CloudinaryResourceType.Image;

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: resourceType,
          folder: 'vwc_contracts',
        ),
      );

      return {
        'url': response.secureUrl,
        'publicId': response.publicId,
        'resourceType': isPdf ? 'raw' : 'image',
      };
    } catch (e) {
      print('Cloudinary contract upload error: $e');
      return null;
    }
  }

  /// Deletes a contract permanently from Cloudinary servers using its publicId.
  static Future<bool> deleteContract(String publicId, String resourceType) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp.toString());

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy',
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'timestamp': timestamp.toString(),
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      final json = jsonDecode(response.body);
      return json['result'] == 'ok';
    } catch (e) {
      print('Cloudinary delete error: $e');
      return false;
    }
  }

  /// Generates SHA-1 signature required by Cloudinary Destroy API
  static String _generateSignature(String publicId, String timestamp) {
    final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    return sha1.convert(utf8.encode(toSign)).toString();
  }
}