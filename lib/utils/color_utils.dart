import 'package:flutter/painting.dart';
import 'package:hacki/styles/styles.dart';

abstract final class ColorUtils {
  static final Map<int, (Color, Color)> levelToRainbowBorderColors =
      <int, (Color, Color)>{};

  static (Color, Color) getRainbowColor(int level, Color background) {
    const int colorCount = 6;

    // If id is larger than 6, take modulo
    int index = level % colorCount;
    final int key = index + background.hashCode;

    final (Color, Color)? cachedColor = levelToRainbowBorderColors[key];

    if (cachedColor != null) return cachedColor;

    // Ensure positive index
    if (index < 0) {
      index += colorCount;
    }

    // Evenly distribute hue across 6 colors
    final double hue = (index / colorCount) * 360.0;

    // Adjust saturation & lightness based on background brightness
    final bool isDarkBg = background.computeLuminance() < 0.5;
    const double saturation = 0.85;
    final double lightness = isDarkBg ? 0.60 : 0.45;
    final Color color = HSLColor.fromAHSL(
      1, // Fully opaque
      hue,
      saturation,
      lightness,
    ).toColor();

    final bool isDarkColor = color.computeLuminance() < 0.5;
    final Color foregroundColor = isDarkColor ? Palette.white : Palette.black;
    levelToRainbowBorderColors[key] = (color, foregroundColor);
    return (color, foregroundColor);
  }
}
