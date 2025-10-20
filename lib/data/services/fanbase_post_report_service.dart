import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class FanbasePostReportService {
  /// Reports a fanbase post with a specific reason
  ///
  /// [reportedPostId] - The ID of the post being reported
  /// [reportedUserId] - The ID of the post creator
  /// [reason] - The reason for reporting (e.g., 'Spam', 'Inappropriate content')
  /// [description] - Optional additional details about the report
  static Future<Map<String, dynamic>> reportPost({
    required String reportedPostId,
    required String reportedUserId,
    required String reason,
    String? description,
    required BuildContext context,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final reportData = {
        'reportedUserId': reportedUserId,
        'reportedPostId': reportedPostId,
        'reason': description != null && description.isNotEmpty
            ? '$reason - $description'
            : reason,
      };

      print('Sending post report data: $reportData'); // Debug log

      final response = await dio.post('/post-reports', data: reportData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Report submitted successfully',
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to submit report',
        };
      }
    } on DioException catch (e) {
      print('DioException in reportPost: ${e.response?.data}'); // Debug log
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      return {
        'success': false,
        'message': 'Failed to submit report: $errorMessage',
      };
    } catch (e) {
      print('General exception in reportPost: $e'); // Debug log
      return {
        'success': false,
        'message': 'Failed to submit report: $e',
      };
    }
  }

  /// Gets all reports submitted by the current user
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
