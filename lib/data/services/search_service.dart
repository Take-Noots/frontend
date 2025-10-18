import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class SearchService {
  static String get baseUrl => '${AppConstants.baseUrl}/search';

  Future<Map<String, dynamic>> search(String query) async {
    final response = await http.get(Uri.parse('$baseUrl?q=$query'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load search results');
    }
  }
}
