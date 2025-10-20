import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Base URL for the backend API - automatically switches based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Running on browser
      return 'http://localhost:3000';
    } else {
      // Running on Android/iOS (mobile)
      // return 'https://unthreshed-eugenic-edgar.ngrok-free.dev';
      return 'https://jeremiah-unphotographable-basely.ngrok-free.dev';
    }
  }

  // Base URL for Spotify API
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';

  // Spotify Access Token
  static const String spotifyAccessToken =
      'BQBEc5YFcCYeQkFF9uiVhEtwu6VCvON7qNw8kDjXXj2WtPWRBqN34cSaMEfI-E2dPGyCaqHrSzeNOUaqvM_CoMXZFqRGe0z-mjpFkZt16tKnBoixL6oQnBIb8sn5oMbIcF5M9QfQaTO8Q7Ht14s7nDtUw1fMwXOGEsZD_--SaN4JOVJjdyWGQHxMPMOrjvu-063nNY54NPrBwvmN9SDRESwFdSjYMZ0CMyGtwgGG2FEi2D5O7NKo36qxSSSslbSfAA';
}
