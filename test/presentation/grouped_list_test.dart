import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/app/theme/theme.dart';
import 'package:odolog/presentation/common/grouped_list.dart';

const _key = Key('shot');
const _width = 411;

Future<Uint8List> _frame(WidgetTester tester) async {
  late Uint8List bytes;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject(find.byKey(_key)) as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = data!.buffer.asUint8List();
  });
  return bytes;
}

int _pixel(Uint8List bytes, int x, int y) {
  final i = (y * _width + x) * 4;
  return bytes[i] << 16 | bytes[i + 1] << 8 | bytes[i + 2];
}

void main() {
  testWidgets('a pressed first row shows ink inside the card corners only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: _key,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: GroupedSliverList(
                    itemCount: 3,
                    itemBuilder: (context, i) =>
                        ListTile(title: Text('Row $i'), onTap: () {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rest = await _frame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Row 0')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    final pressed = await _frame(tester);
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(pressed, isNot(orderedEquals(rest)));
    // The card's top left corner pixel is outside its rounded corner.
    expect(_pixel(pressed, 17, 17), _pixel(rest, 17, 17));
  });
}
