import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'xnzld1tf',
    'YOUR_UPLOAD_PRESET',
    cache: false,
  );

  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}