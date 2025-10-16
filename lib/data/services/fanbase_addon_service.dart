import 'dart:convert';
import 'package:http/http.dart' as http;

class FanbaseAddonService {
  static const String baseUrl =
      'http://localhost:3000/fanbase'; // not fanbase-addon

  /// Fetches the rules for a given fanbase
  static Future<List<String>> getRules(String fanbaseId) async {
    final url = Uri.parse('$baseUrl/$fanbaseId/rules');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data
            .map<String>((e) => e is Map && e.containsKey('rule')
                ? e['rule'] ?? ''
                : e.toString())
            .where((rule) => rule.isNotEmpty)
            .toList();
      }
      return [];
    } else {
      throw Exception(
          'Failed to load fanbase rules: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Updates the rules for a given fanbase (owner only)
  static Future<void> updateRules(
    String fanbaseId,
    List<String> rules, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/$fanbaseId/rules');
    final body = json.encode({
      'rules': rules.map((r) => {'rule': r}).toList(),
    });
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    if (response.statusCode != 200) {
      String msg = 'Failed to update fanbase rules: ${response.statusCode}';
      try {
        final error = json.decode(response.body);
        if (error is Map && error['message'] != null) {
          msg += ' - ${error['message']}';
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
