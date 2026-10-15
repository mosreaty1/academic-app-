import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rashia_academy/core/l10n.dart';
import 'package:rashia_academy/core/theme.dart';
import 'package:rashia_academy/data/app_state.dart';
import 'package:rashia_academy/models/models.dart';
import 'package:rashia_academy/screens/auth/login_screen.dart';
import 'package:rashia_academy/screens/common/exams_screen.dart';
import 'package:rashia_academy/screens/common/lessons_screen.dart';
import 'package:rashia_academy/screens/common/question_bank_screen.dart';
import 'package:rashia_academy/screens/student/student_home.dart';
import 'package:rashia_academy/screens/common/more_screen.dart';
import 'package:rashia_academy/screens/common/subscription_screen.dart';
import 'package:rashia_academy/screens/teacher/students_screen.dart';
import 'package:rashia_academy/screens/teacher/teacher_subscriptions.dart';

Future<AppState> host(WidgetTester t, String? uid, Widget screen,
    {bool ar = true}) async {
  t.view.physicalSize = const Size(1080, 2200);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final s = AppState.seeded()..isAr = ar;
  if (uid != null) s.login(s.user(uid));
  await t.pumpWidget(ChangeNotifierProvider.value(
    value: s,
    child: Consumer<AppState>(
      builder: (_, st, __) => MaterialApp(
        locale: Locale(st.isAr ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: screen,
      ),
    ),
  ));
  await t.pump(const Duration(milliseconds: 400));
  return s;
}

void main() {
  test('every student has a unique ID', () {
    final s = AppState.seeded();
    final codes = s.students.map((u) => u.code).toList();
    expect(codes.every((c) => RegExp(r'^RB[123]-\d{4}$').hasMatch(c)), isTrue);
    expect(codes.toSet().length, codes.length);
    expect(s.user('s1').code, 'RB2-1001');
  });

  test('sign in by student ID, phone, and failures', () async {
    final s = AppState.seeded();
    expect(await s.signIn('rb2-1001', '123456'), isNull);
    expect(s.me!.id, 's1');
    s.logout();
    expect(await s.signIn('01112223344', '123456'), isNull);
    expect(s.me!.role, UserRole.parent);
    s.logout();
    expect(await s.signIn('01001234567', '123456'), isNull);
    expect(s.me!.role, UserRole.teacher);
    s.logout();
    expect(await s.signIn('RB9-9999', '123456'), 'not_found');
    expect(await s.signIn('RB2-1001', 'nope'), 'wrong_password');
    expect(await s.signIn('', ''), 'not_found');
    expect(s.me, isNull);
  });

  test('lesson access follows the subscription', () {
    final s = AppState.seeded();
    final free = s.lessons.firstWhere((l) => !l.premium && l.grade == 2);
    final paid = s.lessons.firstWhere((l) => l.premium && l.grade == 2);
    expect(s.canWatch('s1', paid), isTrue); // Adam is subscribed
    expect(s.canWatch('s7', free), isTrue);
    expect(s.canWatch('s7', paid), isFalse); // Hoda is not
    expect(s.canWatch('s11', s.lessons.firstWhere((l) => l.premium && l.grade == 3)),
        isFalse); // Jana expired
  });

  test('activation codes: redeem, reuse, wrong grade, invalid', () async {
    final s = AppState.seeded();
    expect(s.hasAccess('s7'), isFalse);
    expect(await s.redeemCode('s7', 'BIO1-TERM'), 'wrong_grade');
    expect(await s.redeemCode('s7', 'nope'), 'invalid');
    expect(await s.redeemCode('s7', 'bio2-mnth'), 'ok');
    expect(s.hasAccess('s7'), isTrue);
    expect(await s.redeemCode('s8', 'BIO2-MNTH'), 'used');
    expect(await s.redeemCode('s11', 'USED-0001'), 'used');
  });

  test('subscriptions extend instead of overwrite', () {
    final s = AppState.seeded();
    final before = s.subscriptionOf('s1')!.end;
    s.grantSubscription('s1', AppState.plan('term'), SubSource.manual);
    final after = s.subscriptionOf('s1')!.end;
    expect(after.isAfter(before.add(const Duration(days: 100))), isTrue);
  });

  test('generated codes are unique and redeemable', () async {
    final s = AppState.seeded();
    final made = s.generateCodes('term', 3, 20);
    expect(made.map((c) => c.code).toSet().length, 20);
    expect(await s.redeemCode('s12', made.first.code), 'ok');
    expect(s.hasAccess('s12'), isTrue);
  });

  test('adding a student issues the next ID and links the parent', () async {
    final s = AppState.seeded();
    s.login(s.user('t1'));
    final u = await s.addStudent(
        name: const Bi('طالب جديد', 'New Student'),
        grade: 2,
        section: 'A',
        parentPhone: '01112223344',
        password: '999999');
    expect(u.code, 'RB2-1006');
    expect(s.user('p1').childIds, contains(u.id));
  });

  testWidgets('login screen signs in with the prefilled demo account', (t) async {
    final s = await host(t, null, const LoginScreen());
    await t.tap(find.byType(FilledButton));
    await t.pump(const Duration(milliseconds: 200));
    expect(s.me?.id, 's1');
    expect(t.takeException(), isNull);
  });

  testWidgets('login shows an error for a wrong password', (t) async {
    final s = await host(t, null, const LoginScreen(), ar: false);
    await t.enterText(find.byType(TextField).last, 'wrong');
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(s.me, isNull);
    expect(find.text('Incorrect password'), findsOneWidget);
  });

  for (final ar in [true, false]) {
    testWidgets('lessons + subscription + id card render ar=$ar', (t) async {
      for (final entry in <(String, Widget)>[
        ('s1', const LessonsScreen()),
        ('s7', const LessonsScreen()),
        ('t1', const LessonsScreen()),
        ('s7', const SubscriptionScreen(studentId: 's7')),
        ('p1', const SubscriptionScreen(studentId: 's2')),
        ('t1', const TeacherSubscriptionsScreen()),
        ('t1', const StudentsScreen()),
        ('s1', const MoreScreen(entries: [])),
      ]) {
        await t.pumpWidget(const SizedBox());
        await host(t, entry.$1, entry.$2, ar: ar);
        expect(t.takeException(), isNull, reason: '${entry.$1} ${entry.$2}');
      }
    });
  }

  testWidgets('locked lesson opens the paywall, free lesson opens the player', (t) async {
    await host(t, 's7', const LessonsScreen(), ar: false);
    await t.tap(find.text('Digestive enzymes'));
    await t.pumpAndSettle();
    expect(find.text('This lesson is for subscribers'), findsOneWidget);
    await t.tap(find.text('View subscription plans'));
    await t.pumpAndSettle();
    expect(find.text('Choose a plan'), findsOneWidget);
  });

  testWidgets('redeem a code from the subscription screen', (t) async {
    final s = await host(t, 's7', const SubscriptionScreen(studentId: 's7'), ar: false);
    await t.scrollUntilVisible(find.byType(TextField), 300, scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byType(TextField), 'BIO2-MNTH');
    await t.scrollUntilVisible(find.text('Redeem code'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Redeem code'));
    await t.pumpAndSettle();
    expect(s.hasAccess('s7'), isTrue);
  });

  testWidgets('redeeming a code shows the celebration dialog', (t) async {
    await host(t, 's7', const SubscriptionScreen(studentId: 's7'), ar: false);
    await t.scrollUntilVisible(find.byType(TextField), 300, scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byType(TextField), 'BIO2-MNTH');
    await t.scrollUntilVisible(find.text('Redeem code'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Redeem code'));
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 900));
    expect(find.text('You are subscribed'), findsOneWidget);
    expect(find.text('Start learning'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('practice answers get encouraging feedback', (t) async {
    await host(t, 's1', const QuestionBankScreen(), ar: false);
    await t.tap(find.text('Salivary amylase'));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Correct! Nice work, keep going.'), findsOneWidget);
  });

  testWidgets('a perfect exam gets the outstanding message', (t) async {
    await host(t, 's7', const ExamResultScreen(examId: 'e21', studentId: 's7'), ar: false);
    await t.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Outstanding!'), findsOneWidget);
    expect(find.text('Practise similar questions'), findsOneWidget);
  });

  testWidgets('home shows a continue-learning card by student stage', (t) async {
    await host(t, 's1', StudentHome(onTab: (_) {}), ar: false);
    await t.pump(const Duration(milliseconds: 800));
    expect(find.text('Pick up where you left off'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await host(t, 's2', StudentHome(onTab: (_) {}), ar: false);
    await t.pump(const Duration(milliseconds: 800));
    expect(find.text('Start your next lesson'), findsOneWidget);
  });
}
