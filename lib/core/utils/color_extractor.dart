import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  /// Extracts a dominant dark color from an image URL
  static Future<String?> extractBackgroundColor(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100), 
        maximumColorCount: 10,
      );

      
      Color? extractedColor = paletteGenerator.darkMutedColor?.color ??
          paletteGenerator.darkVibrantColor?.color ??
          paletteGenerator.dominantColor?.color;

      if (extractedColor != null) {
        // Check if the color is dark enough, if not, darken it
        if (!_isDarkEnough(extractedColor)) {
          extractedColor = _darkenColor(extractedColor);
        }
        
        // Convert to hex string
        return _colorToHex(extractedColor);
      }
      
      return null;
    } catch (e) {
      print('Error extracting color from $imageUrl: $e');
      return null;
    }
  }

  /// Checks if a color is dark enough for use as background
  static bool _isDarkEnough(Color color) {
    // Calculate relative luminance (0 for black, 1 for white)
    double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    
    // Return true if the color is dark enough (luminance < 0.4)
    return luminance < 0.4;
  }

  /// Darkens a color by applying a factor
  static Color _darkenColor(Color color) {
    const double darkenFactor = 0.6; // Higher values make the color darker
    return Color.fromARGB(
      color.alpha,
      (color.red * darkenFactor).round(),
      (color.green * darkenFactor).round(),
      (color.blue * darkenFactor).round(),
    );
  }

  /// Converts a Color to hex string format
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Converts a hex string to Color
  static Color hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  /// Gets a default background color based on theme
  static String getDefaultBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? '#112525' : '#F5F5F5';
  }
}
