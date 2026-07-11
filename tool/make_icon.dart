// Generated launcher icon for OdoLog: a minimal amber fuel gauge on ink.
// Regenerate with: dart run tool/make_icon.dart (then: dart run flutter_launcher_icons)

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int canvas = 1024;
const double center = canvas / 2;

// Palette tokens from docs/design.md.
final img.Color ink = img.ColorRgba8(0x10, 0x14, 0x18, 0xFF);
final img.Color amber = img.ColorRgba8(0xFF, 0xB3, 0x00, 0xFF);
final img.Color clear = img.ColorRgba8(0, 0, 0, 0);

/// Draws the amber gauge mark centered on [image]. [dialRadius] is the arc
/// centerline; the visible mark spans roughly dialRadius + arcThickness / 2.
void drawGauge(
  img.Image image, {
  required double dialRadius,
  required double arcThickness,
  required double gapDegrees,
  required double needleLength,
  required double needleThickness,
  required double needleAngleDegrees,
  required double tailLength,
  required double tailThickness,
  required double pivotRadius,
}) {
  // The dial opens at the bottom (screen angle 90 degrees), with a gap of
  // gapDegrees centered there. The arc sweeps the rest, over the top.
  final double start = 90 + gapDegrees / 2;
  final double end = 450 - gapDegrees / 2;
  final int stampRadius = (arcThickness / 2).round();
  for (double deg = start; deg <= end; deg += 0.5) {
    final double rad = deg * math.pi / 180;
    final int x = (center + dialRadius * math.cos(rad)).round();
    final int y = (center + dialRadius * math.sin(rad)).round();
    img.fillCircle(
      image,
      x: x,
      y: y,
      radius: stampRadius,
      color: amber,
      antialias: true,
    );
  }

  // Needle pointing toward full (up and to the right): a tapered pointer from
  // the wide hub to a rounded point, with a short counterweight tail.
  final double needleRad = needleAngleDegrees * math.pi / 180;
  stampTaper(
    image,
    angle: needleRad,
    length: needleLength,
    baseHalf: needleThickness / 2,
    tipHalf: 5,
  );
  final double tailRad = (needleAngleDegrees + 180) * math.pi / 180;
  stampTaper(
    image,
    angle: tailRad,
    length: tailLength,
    baseHalf: tailThickness / 2,
    tipHalf: tailThickness / 2 - 6,
  );

  // Pivot hub last, so it sits cleanly over the needle base.
  img.fillCircle(
    image,
    x: center.round(),
    y: center.round(),
    radius: pivotRadius.round(),
    color: amber,
    antialias: true,
  );
}

/// Stamps a tapered rounded bar from the canvas center outward along [angle],
/// shrinking from [baseHalf] to [tipHalf] over [length]. Used for the needle.
void stampTaper(
  img.Image image, {
  required double angle,
  required double length,
  required double baseHalf,
  required double tipHalf,
}) {
  for (double t = 0; t <= length; t += 1) {
    final double frac = t / length;
    final int x = (center + t * math.cos(angle)).round();
    final int y = (center + t * math.sin(angle)).round();
    final int r = (baseHalf + (tipHalf - baseHalf) * frac).round();
    img.fillCircle(image, x: x, y: y, radius: r, color: amber, antialias: true);
  }
}

/// Returns [amber coverage fraction, centroid offset from center in pixels].
List<double> measure(img.Image image) {
  var count = 0;
  var sumX = 0.0;
  var sumY = 0.0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final img.Pixel p = image.getPixel(x, y);
      final bool isAmber =
          p.a > 100 && p.r > 150 && p.g > 90 && p.g < 220 && p.b < 90;
      if (isAmber) {
        count++;
        sumX += x;
        sumY += y;
      }
    }
  }
  final double fraction = count / (image.width * image.height);
  final double cx = sumX / count;
  final double cy = sumY / count;
  final double offset = math.sqrt(
    math.pow(cx - center, 2) + math.pow(cy - center, 2),
  );
  return <double>[fraction, offset];
}

void main() {
  final Directory iconDir = Directory('assets/icon');
  iconDir.createSync(recursive: true);
  Directory('tmp').createSync(recursive: true);

  // Full icon: ink background, mark at roughly 58 percent of the canvas.
  final img.Image icon = img.Image(
    width: canvas,
    height: canvas,
    numChannels: 4,
  );
  img.fill(icon, color: ink);
  drawGauge(
    icon,
    dialRadius: 268,
    arcThickness: 62,
    gapDegrees: 56,
    needleLength: 210,
    needleThickness: 36,
    needleAngleDegrees: -48,
    tailLength: 74,
    tailThickness: 40,
    pivotRadius: 60,
  );
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));

  // Adaptive foreground: transparent, mark fits the central 66 percent safe
  // zone (extent radius near 320 of the 512 half canvas).
  final img.Image fg = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.fill(fg, color: clear);
  drawGauge(
    fg,
    dialRadius: 286,
    arcThickness: 64,
    gapDegrees: 56,
    needleLength: 224,
    needleThickness: 38,
    needleAngleDegrees: -48,
    tailLength: 80,
    tailThickness: 42,
    pivotRadius: 64,
  );
  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));

  // A 48 pixel preview to confirm the mark survives at launcher size.
  final img.Image preview = img.copyResize(
    icon,
    width: 48,
    height: 48,
    interpolation: img.Interpolation.average,
  );
  File('tmp/icon_preview_48.png').writeAsBytesSync(img.encodePng(preview));

  final List<double> stats = measure(icon);
  final double coverage = stats[0] * 100;
  final double offset = stats[1];
  final double offsetPercent = offset / canvas * 100;
  stdout.writeln('amber coverage: ${coverage.toStringAsFixed(2)} percent');
  stdout.writeln(
    'centroid offset: ${offset.toStringAsFixed(1)} px '
    '(${offsetPercent.toStringAsFixed(2)} percent of canvas)',
  );

  if (coverage < 8 || coverage > 30) {
    stderr.writeln('FAIL: coverage outside 8 to 30 percent');
    exit(1);
  }
  if (offsetPercent > 5) {
    stderr.writeln('FAIL: centroid offset above 5 percent of canvas');
    exit(1);
  }
  stdout.writeln('OK: within coverage and centering bounds');
}
