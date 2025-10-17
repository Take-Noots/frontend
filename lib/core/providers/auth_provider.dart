import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isSpotifyLinked;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isSpotifyLinked,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isSpotifyLinked: json['isSpotifyLinked'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isSpotifyLinked': isSpotifyLinked,
    };
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isSpotifyLinked = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSpotifyLinked => _isSpotifyLinked;

  void setUser(Map<String, dynamic> userData) {
    _user = User.fromJson(userData);
    _isSpotifyLinked = userData['isSpotifyLinked'] as bool;
    _saveUserDataToSharedPreferences(userData);
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  void login(Map<String, dynamic> userData, String token) {
    setUser(userData);
    setToken(token);
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserDataToSharedPreferences(
      Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving user data to SharedPreferences: $e');
    }
  }

  // Clear user data from SharedPreferences
  Future<void> _clearUserDataFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Error clearing user data from SharedPreferences: $e');
    }
  }

  // Load user data from SharedPreferences (for app restart)
  Future<void> loadUserDataFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data from SharedPreferences: $e');
    }
  }
}
