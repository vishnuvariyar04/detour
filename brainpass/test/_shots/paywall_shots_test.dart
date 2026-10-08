// Paywall pages rendered with sample Indian prices (throwaway harness).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:brainpass/theme.dart';
import 'package:brainpass/screens/paywall_screen.dart';

const scratch =
    r'C:\Users\vishn\AppData\Local\Temp\claude\C--dev-detour\b71f8aa8-ef2a-4fb3-8036-40edd9c8e623\scratchpad';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

const _ctx = PresentedOfferingContext('default', null, null);

Package _pkg(String id, PackageType t, double price, String ps,
        {IntroductoryPrice? intro, String? perWeek}) =>
    Package(
      id,
      t,
      StoreProduct('nupo.$id', '', 'Nupo $id', price, ps, 'INR',
          introductoryPrice: intro, pricePerWeekString: perWeek),
      _ctx,
    );

Future<List<Package>> _sample() async => [
      _pkg(r'$rc_weekly', PackageType.weekly, 30, '₹30.00'),
      _pkg(r'$rc_lifetime', PackageType.lifetime, 1500, '₹1,500.00'),
      _pkg(r'$rc_annual', PackageType.annual, 500, '₹500.00',
          intro: const IntroductoryPrice(0, '₹0', 'P1W', 1, PeriodUnit.day, 7),
          perWeek: '₹9.58'),
    ];

Future<void> _snap(WidgetTester t, GlobalKey key, String name) async {
  await t.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      await precacheImage((el.widget as Image).image, el);
    }
  });
  await t.pump(const Duration(milliseconds: 500));
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$scratch\\$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

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
  });

  testWidgets('paywall pages', (t) async {
    t.view.physicalSize = const Size(412 * 2, 892 * 2);
    t.view.devicePixelRatio = 2;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.parent(),
        home: PaywallScreen(dismissible: true, loadPackages: _sample),
      ),
    ));
    await t.pumpAndSettle();
    await _snap(t, key, 'pw1');
    await t.tap(find.textContaining('Try for'));
    await t.pumpAndSettle();
    await _snap(t, key, 'pw2');
    await t.tap(find.text('Continue for FREE'));
    await t.pumpAndSettle();
    await _snap(t, key, 'pw3');
  });
}
