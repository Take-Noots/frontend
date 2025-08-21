import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class PostReportService {
  static Future<Map<String, dynamic>> reportPost({
    required String reportedUserId,
    required String reportedPostId,
    required String reason,
    required BuildContext context,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final reportData = {
        'reportedUserId': reportedUserId,
        'reportedPostId': reportedPostId,
        'reason': reason,
      };

      final response = await dio.post('/post-reports', data: reportData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Report submitted successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to submit report',
        };
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      return {
        'success': false,
        'message': 'Failed to submit report: $errorMessage',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit report: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMyReports(
    BuildContext context,
  ) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/post-reports/my-reports');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch reports',
        };
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      return {
        'success': false,
        'message': 'Failed to fetch reports: $errorMessage',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch reports: $e',
      };
    }
  }
}
