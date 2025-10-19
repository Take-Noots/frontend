import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/advertisement_model.dart';

class AdvertisementService {
  // Either an AuthService (for authenticated calls) or a standalone Dio
  // (for unauthenticated calls) can be provided.
  final AuthService? authService;
  final Dio? unauthenticatedDio;

  // Default constructor for authenticated usage
  AdvertisementService(this.authService) : unauthenticatedDio = null;

  // Named constructor for unauthenticated usage with a provided Dio
  AdvertisementService.unauthenticated(this.unauthenticatedDio)
      : authService = null;

  Dio get dio => unauthenticatedDio ?? authService!.dio;

  Future<Map<String, dynamic>> createAdvertisement({
    required String title,
    required String description,
    String? image,
    String? video,
    String? contactDetails,
    String? location,
    String? genre,
    String? hashtags,
    String? keywords,
  }) async {
    try {
      if (authService == null) {
        return {
          'success': false,
          'message': 'Authentication required to create advertisement'
        };
      }

      await authService!.initialize();

      final response = await dio.post(
        '/advertisement/create',
        data: {
          'title': title,
          'description': description,
          'image': image,
          'video': video,
          'contactDetails': contactDetails,
          'location': location,
          'genre': genre,
          'hashtags': hashtags,
          'keywords': keywords,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Advertisement created successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to create advertisement'
        };
      }
    } on DioException catch (e) {
      debugPrint('Create advertisement error: ${e.message}');
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data?['message'] ?? 'Failed to create advertisement'
        };
      }
      return {
        'success': false,
        'message': 'Connection error. Please check your connection and try again.'
      };
    } catch (e) {
      debugPrint('Create advertisement error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> fetchAdvertisementsByUser(String userId) async {
    try {
      if (authService != null) {
        await authService!.initialize();
      }

      final response = await dio.get('/advertisement/user/$userId');

      if (response.statusCode == 200) {
        List<Advertisement> advertisements = (response.data as List)
            .map((json) => Advertisement.fromJson(json))
            .toList();
        return {
          'success': true,
          'data': advertisements,
          'message': 'Advertisements fetched successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch advertisements'
        };
      }
    } on DioException catch (e) {
      debugPrint('Fetch advertisements error: ${e.message}');
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data?['message'] ?? 'Failed to fetch advertisements'
        };
      }
      return {
        'success': false,
        'message': 'Connection error. Please check your connection and try again.'
      };
    } catch (e) {
      debugPrint('Fetch advertisements error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> updateAdvertisement(String id, Map<String, dynamic> data) async {
    try {
      if (authService == null) {
        return {'success': false, 'message': 'Authentication required to update advertisement'};
      }

      await authService!.initialize();

      final response = await dio.post('/advertisement/$id', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data, 'message': 'Advertisement updated successfully'};
      }

      return {'success': false, 'message': response.data?['message'] ?? 'Failed to update advertisement'};
    } catch (e) {
      debugPrint('Update advertisement error: $e');
      return {'success': false, 'message': 'An error occurred updating advertisement'};
    }
  }
}
