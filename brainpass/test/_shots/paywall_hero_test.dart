// Paywall hero (throwaway harness, like store_slides_test.dart): the home
// screen, an arrow from YouTube, and the lesson that opens first, on a
// transparent background. Output goes to the scratchpad; the chosen PNG is
// copied into assets/paywall/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainpass/theme.dart';

import 'store_slides_test.dart' as s;

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

Widget hero() => SizedBox(
  width: 520,
  height: 500,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 22,
        top: 70,
        child: s.tilt(-7, s.Phone(width: 196, child: const s.HomeScreen(tap: 0, scale: 0.8))),
      ),
      Positioned(
        right: 18,
        top: 34,
        child: s.tilt(4, s.Phone(width: 262, child: s.shot('s_lesson.png'))),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: s.Arrow(const Offset(80, 226), const Offset(158, 110),
              const Offset(252, 186), const Color(0xFF7C3AED)),
        ),
      ),
      Positioned(
        right: 40,
        top: 0,
        child: s.tag('YouTube opens after this', icon: Icons.lock_rounded, size: 15),
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _font('Nunito', [
      for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Nunito-$w.ttf',
    ]);
    await _font('MaterialIcons', [
      r'C:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ]);
    await _font('packages/material_symbols_icons/MaterialSymbolsRounded', [
      r'C:\Users\vishn\AppData\Local\Pub\Cache\hosted\pub.dev\material_symbols_icons-4.2951.0\lib\fonts\MaterialSymbolsRounded.ttf',
    ]);
  });

  testWidgets('paywall_hero', (t) async {
    t.view.physicalSize = const Size(1040, 1000);
    t.view.devicePixelRatio = 2;
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parent(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: RepaintBoundary(key: key, child: hero())),
      ),
    ));
    await t.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        await precacheImage((el.widget as Image).image, el);
      }
    });
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${s.scratch}\\paywall_hero.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
