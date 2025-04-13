/// Provides three types of extended `Gradient`s aptly named `Steps`,
/// as they do not gradate but instead hard-transition.
/// - [LinearSteps]
/// - [RadialSteps]
/// - [SweepSteps]
library gradients;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals, objectRuntimeType;

import '../common.dart';
import 'operators.dart';

/// These `Steps` work a little bit differently than standard `Gradient`s.
///
/// The [Gradient.colors] & [Gradient.stops] properties are duplicated to
/// create hard-edge transitions instead of smooth ones.
abstract class Steps extends Gradient {
  /// These `Steps` work a little bit differently than standard `Gradient`s.
  ///
  /// The [Gradient.colors] & [Gradient.stops] properties are duplicated to
  /// create hard-edge transitions instead of smooth ones.
  ///
  // But while [colors] is a duplicated [Gradient.colors], these [stops], if
  // provided manually instead of using implication, are expected to follow
  // a simple, but important format:
  // - This constructor's `stops` *should* start with a `0.0`, as after
  //   list duplication, the second entry in the list will be eliminated.
  // - This constructor's `stops` *should not* end with a `1.0`, as that will
  //   be added automatically.
  ///
  /// A larger [softness] makes this `FooSteps` more like a standard
  /// `FooGradient`. Default is `0.0`. High-resolution displays are
  /// well-suited for displaying the non-anti-aliased `Steps` formed when
  /// `softness == 0.0`.
  const Steps({
    this.softness = 0.0,
    required List<Color> colors,
    List<double>? stops,
    this.tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) : super(colors: colors, stops: stops, transform: transform);

  /// An incredibly small `double` to provide as an `additive` for each second
  /// entry when duplicating [stops] for this `Steps`.
  ///
  /// A larger  `softness` has the effect of reducing the hard edge in-between
  /// each color in this `Steps`, making it more like its original [Gradient]
  /// counterpart.
  ///
  /// Imagine [stops] is `[0.0, 0.3, 0.8]`*. Providing a `softness` of `0.001`,
  /// the effective, resolved [stops] for this `Gradient` is now:
  ///
  /// `[0.0, 0.001, 0.3, 0.3001, 0.8, 0.8001]`.
  ///
  /// ## \* *Note*:
  /// These `Steps` work a little bit differently than standard `Gradient`s.
  ///
  /// The [Gradient.colors] & [Gradient.stops] fields are overridden
  /// with getters that duplicate these `List`s.
  ///
  /// But while [colors] is a duplicated [Gradient.colors], these [stops], if
  /// provided manually instead of using interpretation, are expected to follow
  /// a simple, but important format:
  /// - This constructor's `stops` *should* start with a `0.0`, as after
  ///   list duplication, the second entry in the list will be eliminated.
  /// - This constructor's `stops` *should not* end with a `1.0`, as that will
  ///   be added automatically.
  final double softness;

  /// How these `Steps` should tile the plane beyond the region before its
  /// starting stop and after its ending stop.
  ///
  /// For details, see [TileMode].
  ///
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_linear.png)
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_radial.png)
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_radialWithFocal.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_radialWithFocal.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_radialWithFocal.png)
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_sweep.png)
  final TileMode tileMode;

  /// A duplicated list of [colors] by [CopyColors].
  List<Color> get steppedColors => ~colors;

  /// A duplicated list of [stops] by [CopyStops] (which may be `null`, in
  /// which case [stopsOrImplied] is employed).
  ///
  /// An optional [softness] is used during the list entry duplication process
  /// to make every duplicate just *slightly* larger than the original entry.
  List<double> get steppedStops {
    final _stops =
        (List<double>.from(stopsOrImplied(stops, colors.length + 1)));
    // If local `stops` is not `null`, above [stopsOrImplied] will return
    // that exact value. In that case, we do not want to build a stop list
    // with an extra value and cut it off... just use the provided `stops`.
    if (stops == null) _stops.removeLast();
    return _stops ^ softness
      ..removeAt(0)
      ..add(1.0);
  }

  /// Resolve these `Steps` to its smooth `Gradient` counterpart by [colors]
  /// and [stops] duplication, considering [softness].
  Gradient get asGradient;

  /// Resolve these `Steps` to its smooth `Gradient` counterpart, then use that
  /// gradient's `createShader()` method.
  ///
  /// According to [Gradient.createShader]:
  /// > "Creates a [Shader] for this gradient to fill the given rect.
  /// >
  /// > If the gradient's configuration is text-direction-dependent, for example
  /// > it uses [AlignmentDirectional] objects instead of [Alignment] objects,
  /// > then the textDirection argument must not be null.
  /// >
  /// > The shader's transform will be resolved from the [transform] of this
  /// > gradient."
  @override
  ui.Shader createShader(ui.Rect rect, {ui.TextDirection? textDirection}) =>
      asGradient.createShader(rect, textDirection: textDirection);
}

/// Construct a [new LinearSteps] that progresses from one color to the next in
/// hard steps as opposed to smooth transitions by way of duplicating colors and
/// stops.
///
/// See [Steps] for more information.
class LinearSteps extends Steps {
  /// A [Steps] gradient differs from a standard [Gradient] in its progression
  /// from one color to the next. Instead of smoothly transitioning between
  /// colors, `Steps` have hard edges created by duplicating colors and
  /// stops.
  ///
  /// A larger [softness] makes this `LinearSteps` more like a standard
  /// `LinearGradient`. Default is `0.001`. High-resolution displays are
  /// well-suited for displaying the non-anti-aliased `Steps` formed when
  /// `softness == 0.0`.
  ///
  /// See [Steps] for more information.
  const LinearSteps({
    double softness = 0.001,
    required List<Color> colors,
    List<double>? stops,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          tileMode: tileMode,
          transform: transform,
        );

  /// The color that correlates to `stops` entry `0` (the first color) is placed
  /// at `AlignmentGeometry` [begin] and the final stop is placed at [end],
  /// with all the intermediate colors filling the space between them.
  ///
  /// See [LinearGradient.begin] & [LinearGradient.end].
  final AlignmentGeometry begin, end;

  @override
  LinearGradient get asGradient => LinearGradient(
      colors: steppedColors,
      stops: steppedStops,
      begin: begin,
      end: end,
      tileMode: tileMode,
      transform: transform);

  /// Returns a new [LinearSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  LinearSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is LinearSteps))
      ? LinearSteps.lerp(a as LinearSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is LinearSteps))
      ? LinearSteps.lerp(this, b as LinearSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [LinearSteps].
  ///
  /// If either `LinearSteps` is `null`, this function linearly interpolates
  /// from a `LinearSteps` that matches the other in [begin], [end], [stops] and
  /// [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// The `t` argument represents a position on the timeline, with `0.0` meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`); `1.0` meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`); and values in between
  /// `0.0 < t < 1.0` meaning that the interpolation is at the relevant point as
  /// a percentage along the timeline between `a` and `b`.
  ///
  /// The interpolation can be extrapolated beyond `0.0` and `1.0`, so negative
  /// values and values greater than `1.0` are valid (and can easily be
  /// generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an `AnimationController`.
  static LinearSteps? lerp(LinearSteps? a, LinearSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    // final stretched = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    //     t < 0.5 ? PrimitiveGradient.from(a) : stretched,
    //     t < 0.5 ? stretched : PrimitiveGradient.from(b),
    //     // t < 0.5 ? t * 2 : (t - 0.5) * 2);
    //     t);

    final interpolated = PrimitiveGradient.byCombination(a, b, t);
    // final interpolated = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    // PrimitiveGradient.from(a), PrimitiveGradient.from(b), t);
    return LinearSteps(
      softness: math.max(0.0, ui.lerpDouble(a.softness, b.softness, t)!),
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t)!,
      end: AlignmentGeometry.lerp(a.end, b.end, t)!,
    );
  }

  /// 📋 Returns a new copy of this `LinearSteps` with any provided
  /// optional parameters overriding those of `this`.
  LinearSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    TileMode? tileMode,
    GradientTransform? transform,
  }) =>
      LinearSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        begin: begin ?? this.begin,
        end: end ?? this.end,
        tileMode: tileMode ?? this.tileMode,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is LinearSteps &&
        other.softness == softness &&
        listEquals<Color>(other.colors, colors) &&
        listEquals<double>(other.stops, stops) &&
        other.tileMode == tileMode &&
        other.begin == begin &&
        other.end == end;
  }



  @override
  String toString() =>
      '${objectRuntimeType(this, 'LinearSteps')} (softness: $softness, '
      '(softness: $softness, colors: $colors, stops: $stops, '
      '$tileMode, begin: $begin, end: $end)';

  @override
  Gradient withOpacity(double opacity)  => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, opacity)!)
            .toList(),
      );
  // '\nresolved colors: $steppedColors, resolved stops: $steppedStops';
}

/// Construct a [new RadialSteps] that progresses from one color to the next in
/// hard steps as opposed to smooth transitions by way of duplicating colors and
/// stops.
///
/// See [Steps] for more information.
class RadialSteps extends Steps {
  /// A [Steps] gradient differs from a standard [Gradient] in its progression
  /// from one color to the next. Instead of smoothly transitioning between
  /// colors, `Steps` have hard edges created by duplicating colors and
  /// stops.
  ///
  /// A larger [softness] makes this `RadialSteps` more like a standard
  /// `RadialGradient`. Default is `0.0025`. High-resolution displays are
  /// well-suited for displaying the non-anti-aliased `Steps` formed when
  /// `softness == 0.0`.
  ///
  /// See [Steps] for more information.
  const RadialSteps({
    double softness = 0.0025,
    required List<Color> colors,
    List<double>? stops,
    this.center = Alignment.center,
    this.radius = 0.5,
    this.focal,
    this.focalRadius = 0.0,
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          tileMode: tileMode,
          transform: transform,
        );

  /// The color that correlates to `stops` entry `0` (the first color) is placed
  /// at `AlignmentGeometry` [center], an offset into the `(-1,-1) x (1,1)`
  /// "paintbox" onto which the gradient will be painted.
  ///
  /// For example, `center: Alignment(0,0)` will place the radial gradient in
  /// the center of this paintbox. This is a standard known as
  /// [Alignment.center].
  ///
  /// See [RadialGradient.center].
  final AlignmentGeometry center;

  /// The distance from [center] to the outer edge of the final [stops] entry,
  /// or final color, is determined by this `radius` as a percentage of the
  /// shortest side of the "paintbox" onto which to paint this gradient.
  ///
  /// In a `100px x 200px` paintbox, a [radius] of `1.0` will place the final
  /// stop at a distance `100px` from the [center].
  ///
  /// See [RadialGradient.radius].
  final double radius;

  /// > "The focal point of the gradient. If specified, the gradient will appear
  /// > to be focused along the vector from [center] to focal."
  ///
  /// See [RadialGradient.focal].
  final AlignmentGeometry? focal;

  /// See [RadialGradient.focalRadius].
  final double focalRadius;

  @override
  RadialGradient get asGradient => RadialGradient(
      colors: steppedColors,
      stops: steppedStops,
      center: center,
      radius: radius,
      focal: focal,
      focalRadius: focalRadius,
      tileMode: tileMode,
      transform: transform);

  /// Returns a new [RadialSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  RadialSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is RadialSteps))
      ? RadialSteps.lerp(a as RadialSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is RadialSteps))
      ? RadialSteps.lerp(this, b as RadialSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [RadialSteps]s.
  ///
  /// If either gradient is `null`, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [center], [radius], [stops]
  /// and [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// The `t` argument represents a position on the timeline, with `0.0` meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`); `1.0` meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`); and values in between
  /// `0.0 < t < 1.0` meaning that the interpolation is at the relevant point as
  /// a percentage along the timeline between `a` and `b`.
  ///
  /// The interpolation can be extrapolated beyond `0.0` and `1.0`, so negative
  /// values and values greater than `1.0` are valid (and can easily be
  /// generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an `AnimationController`.
  static RadialSteps? lerp(RadialSteps? a, RadialSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    // final stretched = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    //     t < 0.5 ? PrimitiveGradient.from(a) : stretched,
    //     t < 0.5 ? stretched : PrimitiveGradient.from(b),
    //     // t < 0.5 ? t * 2 : (t - 0.5) * 2);
    //     t);

    final interpolated = PrimitiveGradient.byCombination(a, b, t);
    // final interpolated = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    // PrimitiveGradient.from(a), PrimitiveGradient.from(b), t);
    return RadialSteps(
      softness: math.max(0.0, ui.lerpDouble(a.softness, b.softness, t)!),
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      center: AlignmentGeometry.lerp(a.center, b.center, t)!,
      radius: math.max(0.0, ui.lerpDouble(a.radius, b.radius, t)!),
      focal: AlignmentGeometry.lerp(a.focal, b.focal, t),
      focalRadius:
          math.max(0.0, ui.lerpDouble(a.focalRadius, b.focalRadius, t)!),
    );
  }

  /// 📋 Returns a new copy of this `RadialSteps` with any provided
  /// optional parameters overriding those of `this`.
  RadialSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? radius,
    AlignmentGeometry? focal,
    double? focalRadius,
    GradientTransform? transform,
  }) =>
      RadialSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        focal: focal ?? this.focal,
        focalRadius: focalRadius ?? this.focalRadius,
      );

  @override
  bool operator ==(Object other) => (identical(this, other))
      ? true
      : (other.runtimeType != runtimeType)
          ? false
          : other is RadialSteps &&
              other.softness == softness &&
              listEquals<Color>(other.colors, colors) &&
              listEquals<double>(other.stops, stops) &&
              other.tileMode == tileMode &&
              other.center == center &&
              other.radius == radius &&
              other.focal == focal &&
              other.focalRadius == focalRadius;


  @override
  String toString() => '${objectRuntimeType(this, 'RadialSteps')}'
      '(softness: $softness, colors: $colors, stops: $stops, '
      '$tileMode, center: $center, radius: $radius, '
      'focal: $focal, focalRadius: $focalRadius)';

  @override
  Gradient withOpacity(double opacity) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, opacity)!)
            .toList(),
      );
  // '\nresolved colors: $steppedColors, resolved stops: $steppedStops';
}

/// Construct a [new SweepSteps] that progresses from one color to the next in
/// hard steps as opposed to smooth transitions by way of duplicating colors and
/// stops.
///
/// See [Steps] for more information.
class SweepSteps extends Steps {
  /// A [Steps] gradient differs from a standard [Gradient] in its progression
  /// from one color to the next. Instead of smoothly transitioning between
  /// colors, `Steps` have hard edges created by duplicating colors and
  /// stops.
  ///
  /// A larger [softness] makes this `SweepSteps` more like a standard
  /// `SweepGradient`. Default is `0.0`. High-resolution displays are
  /// well-suited for displaying the non-anti-aliased `Steps` formed when
  /// `softness == 0.0`.
  ///
  /// See [Steps] for more information.
  const SweepSteps({
    double softness = 0.0,
    required List<Color> colors,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
    this.center = Alignment.center,
    this.startAngle = 0.0,
    this.endAngle = math.pi * 2,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          tileMode: tileMode,
          transform: transform,
        );

  /// The color that correlates to `stops` entry `0` (the first color) is placed
  /// at `AlignmentGeometry` [center], an offset into the `(-1,-1) x (1,1)`
  /// "paintbox" onto which the gradient will be painted.
  ///
  /// For example, `center: Alignment(0,0)` will place the radial gradient in
  /// the center of this paintbox. This is a standard known as
  /// [Alignment.center].
  ///
  /// See [SweepGradient.center].
  final AlignmentGeometry center;

  /// The `startAngle` is just as described by [SweepGradient.startAngle]:
  ///
  /// > "The angle in radians at which stop `0.0` of the gradient is placed.
  /// >
  /// > Defaults to `0.0`."
  ///
  /// The `endAngle` is also just as described by [SweepGradient.endAngle]:
  /// > "The angle in radians at which stop `1.0` of the gradient is placed.
  /// >
  /// > Defaults to  `math.pi * 2`."
  ///
  /// *Where `math` is a named import as `import 'dart:math' as math;`*
  final double startAngle, endAngle;

  @override
  SweepGradient get asGradient => SweepGradient(
      colors: steppedColors,
      stops: steppedStops,
      center: center,
      startAngle: startAngle,
      endAngle: endAngle,
      tileMode: tileMode,
      transform: transform);

  /// Returns a new [SweepSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  SweepSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is SweepSteps))
      ? SweepSteps.lerp(a as SweepSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is SweepSteps))
      ? SweepSteps.lerp(this, b as SweepSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [SweepSteps]s.
  ///
  /// If either gradient is `null`, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [center], [startAngle],
  /// [endAngle], [stops] & [tileMode] and with the same [colors] but
  /// transparent (using [scale]).
  ///
  /// The `t` argument represents a position on the timeline, with `0.0` meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`); `1.0` meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`); and values in between
  /// `0.0 < t < 1.0` meaning that the interpolation is at the relevant point as
  /// a percentage along the timeline between `a` and `b`.
  ///
  /// The interpolation can be extrapolated beyond `0.0` and `1.0`, so negative
  /// values and values greater than `1.0` are valid (and can easily be
  /// generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an `AnimationController`.
  static SweepSteps? lerp(SweepSteps? a, SweepSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    // final stretched = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    //     t < 0.5 ? PrimitiveGradient.from(a) : stretched,
    //     t < 0.5 ? stretched : PrimitiveGradient.from(b),
    //     // t < 0.5 ? t * 2 : (t - 0.5) * 2);
    //     t);

    final interpolated = PrimitiveGradient.byCombination(a, b, t);
    // final interpolated = PrimitiveGradient.fromStretchLerp(a, b, t);
    // final interpolated = PrimitiveGradient.byProgressiveMerge(
    // PrimitiveGradient.from(a), PrimitiveGradient.from(b), t);
    return SweepSteps(
      softness: math.max(0.0, ui.lerpDouble(a.softness, b.softness, t)!),
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      center: AlignmentGeometry.lerp(a.center, b.center, t)!,
      startAngle: math.max(0.0, ui.lerpDouble(a.startAngle, b.startAngle, t)!),
      endAngle: math.max(0.0, ui.lerpDouble(a.endAngle, b.endAngle, t)!),
    );
  }

  /// 📋 Returns a new copy of this `SweepSteps` with any provided
  /// optional parameters overriding those of `this`.
  SweepSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? startAngle,
    double? endAngle,
    GradientTransform? transform,
  }) =>
      SweepSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
        tileMode: tileMode ?? this.tileMode,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) => (identical(this, other))
      ? true
      : (other.runtimeType != runtimeType)
          ? false
          : other is SweepSteps &&
              other.softness == softness &&
              listEquals<Color>(other.colors, colors) &&
              listEquals<double>(other.stops, stops) &&
              other.center == center &&
              other.startAngle == startAngle &&
              other.endAngle == endAngle &&
              other.tileMode == tileMode;



  @override
  String toString() => '${objectRuntimeType(this, 'SweepSteps')}'
      '(softness: $softness, colors: $colors, stops: $stops, '
      '$tileMode, center: $center, '
      'startAngle: $startAngle, endAngle: $endAngle)';

  @override
  Gradient withOpacity(double opacity) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, opacity)!)
            .toList(),
      );
  // '\nresolved colors: $steppedColors, resolved stops: $steppedStops';
}
