import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/fanbase/fanbase_model.dart';
// import '../config.dart';

const String baseUrl = 'http://localhost:3000'; 

class FanbaseService {
  static Future<List<Fanbase>> getAllFanbases() async {
    final response = await http.get(Uri.parse('$baseUrl/fanbase'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Fanbase.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fanbases');
    }
  }

  static Future<Fanbase> getFanbaseById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/fanbase/$id'));

    if (response.statusCode == 200) {
      return Fanbase.fromJson(json.decode(response.body));
    } else {
      throw Exception('Fanbase not found');
    }
  }
}
