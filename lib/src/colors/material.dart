/// Provides [MaterialColor]-related functionality, specifically the generation
/// of `ColorSwatch<int>`s which can fulfill the [new MaterialColor] `swatch`
/// property by consider [SwatchMode] styles.
library colors;

import 'package:flutter/material.dart' show Colors, MaterialAccentColor, MaterialColor;
import 'package:flutter/widgets.dart';
import 'package:nonsense_spectrum/colors.dart';

import 'common.dart';

///     const kShadeCountMaterialAccent = 5;
//
/// The quantity of valid shade map `keys` for a `Map<int, Color> palette`
/// that would generate a [MaterialAccentColor].
const kShadeCountMaterialAccent = 5;

///     const kShadeCountMaterialColor = 10;
//
/// The quantity of valid shade map `keys` for a `Map<int, Color> palette`
/// that would generate a [MaterialColor].
const kShadeCountMaterialColor = 10;

///     const kShadeKeysMaterialAccent = [50, 100, 200, 400, 700];
//
/// The range of valid shade map `keys` for a `Map<int, Color> palette`
/// that would generate a [MaterialAccentColor].
const kShadeKeysMaterialAccent = [50, 100, 200, 400, 700];

// ignore: lines_longer_than_80_chars
///     const kShadeKeysMaterialColor = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
//
/// The range of valid shade map `keys` for a `Map<int, Color> palette`
/// that would generate a [MaterialColor].
const kShadeKeysMaterialColor = [
  50,
  100,
  200,
  300,
  400,
  500,
  600,
  700,
  800,
  900,
];

/// Accepts a `Color` and returns a [MaterialColor] whose primary is the
/// provided `color`✝ and whose `swatch` is generated by one of a number of
/// swatch mapping functions.
///
/// ✝ When using [SwatchMode.fade], `shade500` will not resemble the primary
/// `color`. Instead, the final index `shade900`, or `shade700` for accents,
/// resembles `color`.
MaterialColor materialPrimaryFrom(
        Color color, SwatchMode mode, double? factor) =>
    materialColorFrom(color, mode, factor, true);

/// Accepts a `Color` and returns a [MaterialAccentColor] whose primary is the
/// provided `color`✝ and whose `swatch` is generated by one of a number of
/// swatch mapping functions.
///
/// ✝ When using [SwatchMode.fade], `shade500` will not resemble the primary
/// `color`. Instead, the final index `shade900`, or `shade700` for accents,
/// resembles `color`.
MaterialAccentColor materialAccentFrom(
        Color color, SwatchMode mode, double? factor) =>
    materialColorFrom(color, mode, factor, false);

/// Accepts a `Color` and returns a [MaterialColor] or [MaterialAccentColor]
/// whose primary is the provided `color`✝ and whose `swatch` is generated by
/// one of a number of swatch mapping functions.
///
/// If [isPrimary] is `false`, the return is a five-shade
/// [MaterialAccentColor].
///
/// ✝ When using [SwatchMode.fade], `shade500` will not resemble the primary
/// `color`. Instead, the final index `shade900`, or `shade700` for accents,
/// resembles `color`.
dynamic materialColorFrom(
  Color color,
  SwatchMode mode,
  double? factor,
  bool isPrimary,
) {
  switch (mode) {
    case SwatchMode.shade:
      return isPrimary
          ? MaterialColor(
              color.value,
              mapSwatchByShade(
                color,
                min: factor != null ? -(factor ~/ 2) : -100,
                max: factor != null ? factor ~/ 2 : 100,
                isPrimary: isPrimary,
              ),
            )
          : MaterialAccentColor(
              color.value,
              mapSwatchByShade(
                color,
                min: factor != null ? -(factor ~/ 2) : -100,
                max: factor != null ? factor ~/ 2 : 100,
                isPrimary: isPrimary,
              ),
            );
    case SwatchMode.desaturate:
      return isPrimary
          ? MaterialColor(
              color.value,
              mapSwatchByAlphaBlend(
                color,
                strength: factor,
                isPrimary: isPrimary,
              ),
            )
          : MaterialAccentColor(
              color.value,
              mapSwatchByAlphaBlend(
                color,
                strength: factor,
                isPrimary: isPrimary,
              ),
            );
    case SwatchMode.fade:
      return isPrimary
          ? MaterialColor(
              color.value,
              mapSwatchByOpacity(
                color,
                add: factor?.truncate() ?? 0,
                isPrimary: isPrimary,
              ),
            )
          : MaterialAccentColor(
              color.value,
              mapSwatchByOpacity(
                color,
                add: factor?.truncate() ?? 0,
                isPrimary: isPrimary,
              ),
            );
    case SwatchMode.complements:
      return isPrimary
          ? MaterialColor(
              color.value,
              mapSwatchByComplements(
                color,
                isPrimary: isPrimary,
              ),
            )
          : MaterialAccentColor(
              color.value,
              mapSwatchByComplements(
                color,
                isPrimary: isPrimary,
              ),
            );
  }
}

/// Accepts [Color] `primary` and returns a `Map<int, Color>`
/// with the appropriate keys to form a `ColorSwatch<int>._swatch`,
/// which can fulfill the [new MaterialColor] `swatch` property.
///
/// - `050`: `primary.withWhite(step)`
/// - `100`: `primary.withWhite(step)`
/// - ...
/// - `800`: `primary.withWhite(step)`
/// - `900`: `primary.withWhite(step)`
///
/// Where `step` is determined by finding the range between [min] and [max]
/// and dividing by `10`, considering a `MaterialColor` has ten shades.
///
/// Value for key `500`: passed `primary`
///
/// Default [min] is `-75` and default max is `75`.
///
/// If `min` and `max` are not polar opposites, the value mapped to shade 500
/// will not match the input provided [primary] color.
Map<int, Color> mapSwatchByShade(
  Color primary, {
  int min = -100,
  int max = 100,
  bool isPrimary = true,
}) {
  final count =
      isPrimary ? kShadeCountMaterialColor : kShadeCountMaterialAccent;
  final range = max - min;
  final delta = range / count;
  final shades =
      List<int>.generate(count, (int i) => (max - i * delta).truncate());

  var i = 0;
  return <int, Color>{
    for (var shade
        in isPrimary ? kShadeKeysMaterialColor : kShadeKeysMaterialAccent)
      shade: primary.withWhite(shades[i++])
  };
}

/// Accepts [Color] `primary` and returns a `Map<int, Color>`
/// with the appropriate keys to form a `ColorSwatch<int>._swatch`,
/// which can fulfill the [new MaterialColor] `swatch` property.
///
/// - `050`: `Color.alphaBlend(primary.withOpacity(0.25), Colors.white)`,
/// - `100`: `Color.alphaBlend(primary.withOpacity(0.45), Colors.white)`,
/// - ...
/// - `800`: `Color.alphaBlend(primary.withOpacity(0.4), Colors.black)`,
/// - `900`: `Color.alphaBlend(primary.withOpacity(0.25), Colors.black)`
///
/// The value mapped to shade 500 will always be the input provided
/// [primary] color.
Map<int, Color> mapSwatchByAlphaBlend(
  Color primary, {
  dynamic strength,
  bool isPrimary = true,
}) {
  final alpha = alphaFromStrength(strength) ?? primary.alpha;
  return isPrimary
      ? {
          50: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.15).round()), Colors.white)
              .withAlpha(alpha),
          100: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.25).round()), Colors.white)
              .withAlpha(alpha),
          200: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.4).round()), Colors.white)
              .withAlpha(alpha),
          300: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.6).round()), Colors.white)
              .withAlpha(alpha),
          400: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.8).round()), Colors.white)
              .withAlpha(alpha),
          500: primary.withAlpha(alpha),
          600: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.7).round()), Colors.black)
              .withAlpha(alpha),
          700: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.5).round()), Colors.black)
              .withAlpha(alpha),
          800: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.3).round()), Colors.black)
              .withAlpha(alpha),
          900: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.15).round()), Colors.black)
              .withAlpha(alpha),
        }
      : {
          50: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.4).round()), Colors.white)
              .withAlpha(alpha),
          100: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.75).round()), Colors.white)
              .withAlpha(alpha),
          200: primary.withAlpha(alpha),
          400: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.6).round()), Colors.black)
              .withAlpha(alpha),
          700: Color.alphaBlend(
                  primary.withAlpha((alpha * 0.2).round()), Colors.black)
              .withAlpha(alpha),
        };
}

/// Accepts [Color] `primary` and returns a `Map<int, Color>`
/// with the appropriate keys to form a `ColorSwatch<int>._swatch`,
/// which can fulfill the [new MaterialColor] `swatch` property.
///
/// - `050`: `primary.withOpacity(0.1)`
/// - `100`: `primary.withOpacity(0.2)`
/// - ...
/// - `800`: `primary.withOpacity(0.9)`
/// - `900`: `primary.withOpacity(1.0)`
///
/// The value mapped to shade 500 will not be the input provided
/// [primary] color. It will be [primary] with an opacity of `0.6`.
///
/// All the above is true with the default [add] `== 0`. The `add` is
/// the amount to provide as `primary.withWhite(add)` on top of ramping the
/// opacity with each progressive shade, such as:
///
///     50: primary.withWhite(add).withOpacity(0.1)
Map<int, Color> mapSwatchByOpacity(
  Color primary, {
  int add = 0,
  bool isPrimary = true,
}) {
  final delta = 1.0 /
      (isPrimary ? kShadeCountMaterialColor : (kShadeCountMaterialAccent - 1));
  final keys = isPrimary ? kShadeKeysMaterialColor : kShadeKeysMaterialAccent;
  return <int, Color>{
    for (var k in keys)
      k: primary.withWhite(add).withOpacity(primary.opacity *
          delta *
          (keys.indexOf(k) == 0 ? 0.5 : keys.indexOf(k)))
  };
}

/// Accepts [Color] `primary` and returns a `Map<int, Color>`
/// with the appropriate keys to form a `ColorSwatch<int>._swatch`,
/// which can fulfill the [new MaterialColor] `swatch` property.
///
/// Acquires a `List<Color>` by [primary] with `complementary(10)`.
///
/// - `050`: `primary.withOpacity(0.1)`
/// - `100`: `primary.withOpacity(0.2)`
/// - ...
/// - `800`: `primary.withOpacity(0.9)`
/// - `900`: `primary.withOpacity(1.0)`
Map<int, Color> mapSwatchByComplements(Color primary, {bool isPrimary = true}) {
  // final complements = primary.complementDeca;
  final complements = primary.complementary(
      isPrimary ? kShadeCountMaterialColor : kShadeCountMaterialAccent);
  return isPrimary
      ? {
          50: complements[5],
          100: complements[6],
          200: complements[7],
          300: complements[8],
          400: complements[9],
          500: complements[0],
          600: complements[1],
          700: complements[2],
          800: complements[3],
          900: complements[4],
        }
      : {
          50: complements[3],
          100: complements[4],
          200: complements[0],
          400: complements[1],
          700: complements[2],
        };
}
