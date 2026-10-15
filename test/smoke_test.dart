import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rashia_academy/data/app_state.dart';
import 'package:rashia_academy/main.dart';

Future<AppState> boot(WidgetTester t, String uid, {bool ar = true}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  final state = AppState.seeded()..isAr = ar;
  await t.pumpWidget(ChangeNotifierProvider.value(value: state, child: const RashiaApp()));
  await t.pump(const Duration(milliseconds: 2400));
  await t.pump(const Duration(milliseconds: 600));
  state.login(state.user(uid));
  await t.pump(const Duration(milliseconds: 600));
  return state;
}

Future<void> walkTabs(WidgetTester t, int n) async {
  final nav = find.byType(NavigationDestination);
  expect(nav, findsNWidgets(n));
  for (var i = 0; i < n; i++) {
    await t.tap(nav.at(i));
    await t.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  for (final ar in [true, false]) {
    for (final uid in ['s1', 's2', 's11', 'p1', 't1']) {
      testWidgets('walk $uid ar=$ar', (t) async {
        await boot(t, uid, ar: ar);
        await walkTabs(t, 5);
        expect(tester(t), isNull);
      });
    }
  }
}

Object? tester(WidgetTester t) => t.takeException();
