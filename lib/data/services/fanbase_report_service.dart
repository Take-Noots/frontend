import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'auth_service.dart';

class FanbaseReportService {
  /// Reports a fanbase with a specific reason
  ///
  /// [reportedFanbaseId] - The ID of the fanbase being reported
  /// [reportedUserId] - The ID of the fanbase creator (owner)
  /// [reason] - The reason for reporting (e.g., 'Spam', 'Inappropriate content')
  /// [description] - Optional additional details about the report
  static Future<Map<String, dynamic>> reportFanbase({
    required String reportedFanbaseId,
    required String reportedUserId,
    required String reason,
    String? description,
    required BuildContext context,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      // Use the working post-reports endpoint
      // We'll use reportedPostId to store the fanbase ID
      // and add a special prefix or marker in the reason to identify it as a fanbase report
      final reportData = {
        'reportedUserId': reportedUserId,
        'reportedPostId': reportedFanbaseId, // Store fanbase ID here
        'reason':
            'FANBASE: $reason${description != null && description.isNotEmpty ? ' - $description' : ''}',
      };

      print('Sending fanbase report data: $reportData'); // Debug log

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
      print('DioException: ${e.response?.data}'); // Debug log
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?.toString() ??
          e.message;
      return {
        'success': false,
        'message': 'Failed to submit report: $errorMessage',
      };
    } catch (e) {
      print('General exception: $e'); // Debug log
      return {
        'success': false,
        'message': 'Failed to submit report: $e',
      };
    }
  }

  /// Maps user-friendly reason to backend category
  // static String _mapReasonToCategory(String reason) {
  //   switch (reason.toLowerCase()) {
  //     case 'spam':
  //       return 'spam';
  //     case 'inappropriate content':
  //       return 'inappropriate';
  //     case 'harmful or abusive':
  //       return 'harassment';
  //     case 'intellectual property violation':
  //       return 'copyright';
  //     default:
  //       return 'other';
  //   }
  // }

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
