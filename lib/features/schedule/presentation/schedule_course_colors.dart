import 'package:flutter/material.dart';

class CourseColorPalette {
  const CourseColorPalette._();

  static Color colorForCourse(String courseName, Map<String, int> overrides) {
    final normalizedName = courseName.trim();
    final override = overrides[normalizedName];
    if (override != null) {
      return Color(override);
    }
    final hash = _stableHash(normalizedName.isEmpty ? 'SeekU' : normalizedName);
    final hue = (hash % 360).toDouble();
    var lightness = 0.38;
    Color color;
    do {
      color = HSLColor.fromAHSL(1, hue, 0.46, lightness).toColor();
      lightness -= 0.03;
    } while (_contrastWithWhite(color) < 4.5 && lightness >= 0.24);
    return color;
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static double _contrastWithWhite(Color color) {
    final luminance = color.computeLuminance();
    return 1.05 / (luminance + 0.05);
  }
}
