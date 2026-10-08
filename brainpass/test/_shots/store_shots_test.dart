// Renders the home tabs with sample data for the store screenshots.
// Throwaway: delete the folder when done.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brainpass/storage.dart';
import 'package:brainpass/subscription_service.dart';
import 'package:brainpass/theme.dart';
import 'package:brainpass/screens/home_shell.dart';
import 'package:brainpass/screens/parent_home_screen.dart';

const out = r'C:\Users\vishn\AppData\Local\Temp\claude\C--dev-detour\b71f8aa8-ef2a-4fb3-8036-40edd9c8e623\scratchpad\shots';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _font('Nunito', [
      for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Nunito-$w.ttf',
    ]);
    await _font('packages/material_symbols_icons/MaterialSymbolsRounded', [
      r'C:\Users\vishn\AppData\Local\Pub\Cache\hosted\pub.dev\material_symbols_icons-4.2951.0\lib\fonts\MaterialSymbolsRounded.ttf',
    ]);
    await _font('MaterialIcons', [r'C:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf']);
  });

  Future<void> setup(WidgetTester t) async {
    SharedPreferences.setMockInitialValues({
      'childName': 'Aarav',
      'parentName': 'Priya',
      'ageBand': 'b',
      'childAge': 8,
      'onboardingComplete': true,
      'gatedApps': ['com.google.android.youtube', 'com.mojang.minecraftpe'],
      'appRules': '{"com.google.android.youtube":{"q":3,"m":15,"c":60},"com.mojang.minecraftpe":{"q":3,"m":20,"c":60}}',
      'masterEnabled': true,
    });
    await Storage.init();
    SubscriptionService.hasPro.value = true;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('brainpass/engine'),
      (call) async => switch (call.method) {
        'appStatus' => call.arguments['package'] == 'com.google.android.youtube'
            ? {'usedMs': 18 * 60000, 'remMs': 12 * 60000, 'minutes': 15, 'questions': 3}
            : {'usedMs': 20 * 60000, 'remMs': 0, 'minutes': 20, 'questions': 3},
        'learningProgress' => {
            'stopsDone': 9, 'stopsPlayable': 48, 'currentStopId': '',
            'questionIndex': 3, 'asked': 168, 'right': 146, 'streak': 6,
            'answeredToday': 9, 'week': [6, 9, 4, 12, 8, 10, 9],
          },
        'canDrawOverlays' => true,
        'hasUsageAccess' => true,
        _ => null,
      },
    );
  }

  Future<void> render(WidgetTester t, Widget child, String name, double h) async {
    t.view.physicalSize = Size(1080, h * 2.625);
    t.view.devicePixelRatio = 2.625;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.parent(),
        home: child,
      ),
    ));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2.625);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('learning', (t) async {
    await setup(t);
    await render(t, const HomeShell(), 'tab_learning', 912);
  });

  testWidgets('learning tall', (t) async {
    await setup(t);
    await render(t, const HomeShell(), 'tab_learning_tall', 3000);
  });

  testWidgets('parent', (t) async {
    await setup(t);
    await render(t, const Scaffold(body: ParentHomeScreen(embedded: true)), 'tab_parent', 912);
  });
}
