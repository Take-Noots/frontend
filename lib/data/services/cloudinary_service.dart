import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'dygcsdace';
  static const String uploadPreset = 'profile_pictures_preset';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  /// Upload an image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder ?? 'profile_pictures',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload an image from bytes to Cloudinary
  /// Useful for web or when you have image data as bytes
  Future<String> uploadImageFromBytes(
    List<int> bytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder ?? 'profile_pictures',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete an image from Cloudinary using its public ID
  /// Note: cloudinary_public package doesn't support deletion
  /// You'll need to delete from backend or use Cloudinary Admin API
  Future<void> deleteImage(String publicId) async {
    // This requires admin API access which is not available in cloudinary_public
    // Implement deletion through your backend API instead
    throw UnimplementedError(
      'Image deletion should be handled through backend API',
    );
  }

  /// Extract public ID from Cloudinary URL
  /// Example: https://res.cloudinary.com/demo/image/upload/v1234567890/profile_pictures/abc123.jpg
  /// Returns: profile_pictures/abc123
  String extractPublicId(String url) {
    final parts = url.split('/upload/');
    if (parts.length < 2) return '';

    final pathParts = parts[1].split('/');
    pathParts.removeAt(0); // Remove version

    final publicIdWithExtension = pathParts.join('/');
    // Remove file extension
    return publicIdWithExtension.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
}
