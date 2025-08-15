import 'dart:io';

class AppConstants {
  // Base URL for the backend API
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://backend-nestjs-production-8204.up.railway.app';
    }
    return 'http://localhost:3000';
  }

  // Base URL for Spotify API
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';

  // Spotify Access Token
  static const String spotifyAccessToken =
      'BQBEc5YFcCYeQkFF9uiVhEtwu6VCvON7qNw8kDjXXj2WtPWRBqN34cSaMEfI-E2dPGyCaqHrSzeNOUaqvM_CoMXZFqRGe0z-mjpFkZt16tKnBoixL6oQnBIb8sn5oMbIcF5M9QfQaTO8Q7Ht14s7nDtUw1fMwXOGEsZD_--SaN4JOVJjdyWGQHxMPMOrjvu-063nNY54NPrBwvmN9SDRESwFdSjYMZ0CMyGtwgGG2FEi2D5O7NKo36qxSSSslbSfAA';
}
