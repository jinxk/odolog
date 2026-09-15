// Store listing images for OdoLog: the 512 px Play icon and the 1024x500
// feature graphic (gauge plus the OdoLog wordmark in Inter on ink).
// Regenerate with: flutter test tool/make_store_graphics.dart
// It runs under flutter test because package:image cannot draw a TTF font.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'make_icon.dart' show drawGauge, ink;

const String outDir = 'fastlane/metadata/android/en-US/images';
const double width = 1024;
const double height = 500;
const double gaugeSize = 360;
const double gap = 48;

void main() {
  testWidgets('write store images', (WidgetTester tester) async {
    await tester.runAsync(() async {
      Directory(outDir).createSync(recursive: true);

      final img.Image icon = img.decodePng(
        File('assets/icon/icon.png').readAsBytesSync(),
      )!;
      File('$outDir/icon.png').writeAsBytesSync(
        img.encodePng(
          img.copyResize(
            icon,
            width: 512,
            height: 512,
            interpolation: img.Interpolation.average,
          ),
        ),
      );

      // Same mark and parameters as the launcher icon, drawn on ink so the
      // crop below blends into the background.
      final img.Image gauge = img.Image(width: 1024, height: 1024);
      img.fill(gauge, color: ink);
      drawGauge(
        gauge,
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
      final ui.Codec codec = await ui.instantiateImageCodec(
        img.encodePng(gauge),
      );
      final ui.Image gaugeImage = (await codec.getNextFrame()).image;

      final FontLoader loader = FontLoader('StoreInter')
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(
              File('assets/fonts/InterDisplay-Bold.ttf').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();

      final TextPainter word = TextPainter(
        text: const TextSpan(
          text: 'OdoLog',
          style: TextStyle(
            fontFamily: 'StoreInter',
            fontSize: 130,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()
          ..color = Color.fromARGB(
            255,
            ink.r.toInt(),
            ink.g.toInt(),
            ink.b.toInt(),
          ),
      );
      final double left = (width - (gaugeSize + gap + word.width)) / 2;
      // Source rect is the gauge's extent (about 600 px around the centre).
      canvas.drawImageRect(
        gaugeImage,
        const Rect.fromLTWH(192, 192, 640, 640),
        Rect.fromLTWH(left, (height - gaugeSize) / 2, gaugeSize, gaugeSize),
        Paint()..filterQuality = FilterQuality.high,
      );
      word.paint(
        canvas,
        Offset(left + gaugeSize + gap, (height - word.height) / 2),
      );

      final ui.Image rendered = await recorder.endRecording().toImage(
        width.toInt(),
        height.toInt(),
      );
      final ByteData rgba = (await rendered.toByteData())!;
      final img.Image feature = img.Image.fromBytes(
        width: width.toInt(),
        height: height.toInt(),
        bytes: rgba.buffer,
        numChannels: 4,
      ).convert(numChannels: 3);
      File(
        '$outDir/featureGraphic.png',
      ).writeAsBytesSync(img.encodePng(feature));
    });
  });
}
