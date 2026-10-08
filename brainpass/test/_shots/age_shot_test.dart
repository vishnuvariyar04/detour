import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brainpass/storage.dart';
import 'package:brainpass/theme.dart';
import 'package:brainpass/screens/age_band_screen.dart';
import 'package:brainpass/screens/onboarding/story_flow.dart' show AgeCard;

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  testWidgets('age', (t) async {
    await _font('Nunito', [for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) 'assets/fonts/Nunito-$w.ttf']);
    await _font('MaterialIcons', [r'C:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf']);
    SharedPreferences.setMockInitialValues({'childName': 'Ramu', 'ageBand': 'a'});
    await Storage.init();
    t.view.physicalSize = const Size(1080, 2394);
    t.view.devicePixelRatio = 2.625;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.parent(), home: AgeBandScreen(onNext: () {}))));
    await t.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        await precacheImage((el.widget as Image).image, el);
      }
    });
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('11–12'));
    await t.pump(const Duration(seconds: 1));
    // ignore: avoid_print
    print('SEL ' + t.widgetList<AgeCard>(find.byType(AgeCard)).map((w) => '${w.course.band}=${w.selected}').join(' ') + ' | ' + t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().where((d) => d.contains('Ramu') || d.contains('switch')).join(','));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2.625);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(r'C:\Users\vishn\AppData\Local\Temp\claude\C--dev-detour\b71f8aa8-ef2a-4fb3-8036-40edd9c8e623\scratchpad\age_new.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
