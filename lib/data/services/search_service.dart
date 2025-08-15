import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SearchService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://backend-nestjs-production-8204.up.railway.app/search';
    }
    return 'http://localhost:3000/search';
  }

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
