import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rashia_academy/core/theme.dart';
import 'package:rashia_academy/data/app_state.dart';
import 'package:rashia_academy/models/models.dart';
import 'package:rashia_academy/screens/common/announcements_screen.dart';
import 'package:rashia_academy/screens/common/attendance_screen.dart';
import 'package:rashia_academy/screens/common/exams_screen.dart';
import 'package:rashia_academy/screens/common/homework_screen.dart';
import 'package:rashia_academy/screens/common/materials_screen.dart';
import 'package:rashia_academy/screens/common/progress_screen.dart';
import 'package:rashia_academy/screens/common/question_bank_screen.dart';
import 'package:rashia_academy/screens/common/store_screen.dart';
import 'package:rashia_academy/screens/common/tickets_screen.dart';
import 'package:rashia_academy/screens/teacher/students_screen.dart';
import 'package:rashia_academy/screens/teacher/teacher_attendance.dart';
import 'package:rashia_academy/screens/teacher/teacher_exams.dart';
import 'package:rashia_academy/screens/teacher/teacher_homework.dart';

Future<AppState> host(WidgetTester t, String uid, Widget screen,
    {bool ar = true, bool dark = false}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  t.view.physicalSize = const Size(1080, 2200); // 360 x ~733 dp
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final s = AppState.seeded()
    ..isAr = ar
    ..setDark(dark);
  s.login(s.user(uid));
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
        themeMode: st.themeMode,
        home: screen,
      ),
    ),
  ));
  await t.pump(const Duration(milliseconds: 400));
  return s;
}

void main() {
  final screens = <String, (String, Widget Function(AppState))>{
    'attendance': ('s1', (s) => const AttendanceScreen(studentId: 's1')),
    'exams': ('s1', (s) => const ExamsScreen(studentId: 's1')),
    'exams-parent': ('p1', (s) => const ExamsScreen(studentId: 's2')),
    'result': ('s1', (s) => const ExamResultScreen(examId: 'e21', studentId: 's1')),
    'qb': ('s1', (s) => const QuestionBankScreen()),
    'qb-teacher': ('t1', (s) => const QuestionBankScreen()),
    'homework': ('s1', (s) => const HomeworkScreen(studentId: 's1')),
    'materials': ('s11', (s) => const MaterialsScreen()),
    'materials-teacher': ('t1', (s) => const MaterialsScreen()),
    'store': ('s1', (s) => const StoreScreen()),
    'store-teacher': ('t1', (s) => const StoreScreen()),
    'orders-teacher': ('t1', (s) => const OrdersScreen()),
    'tickets': ('p1', (s) => const TicketsScreen()),
    'tickets-teacher': ('t1', (s) => const TicketsScreen()),
    'announcements': ('s1', (s) => const AnnouncementsScreen()),
    'notifications': ('s1', (s) => const NotificationsScreen()),
    'progress': ('s1', (s) => const ProgressScreen(studentId: 's1')),
    't-attendance': ('t1', (s) => const TeacherAttendanceScreen()),
    't-exams': ('t1', (s) => const TeacherExamsScreen()),
    't-exam-detail': ('t1', (s) => const ExamDetailScreen(examId: 'e21')),
    't-create-exam': ('t1', (s) => const CreateExamScreen()),
    't-homework': ('t1', (s) => const TeacherHomeworkScreen()),
    't-hw-detail': ('t1', (s) => const HomeworkDetailScreen(hwId: 'h22')),
    't-students': ('t1', (s) => const StudentsScreen()),
  };

  for (final dark in [false, true]) {
    for (final ar in [true, false]) {
      for (final e in screens.entries) {
        testWidgets('render ${e.key} ar=$ar dark=$dark', (t) async {
          final s = await host(t, e.value.$1, const SizedBox(), ar: ar, dark: dark);
          await t.pumpWidget(const SizedBox());
          // re-host with the real screen
          await host(t, e.value.$1, e.value.$2(s), ar: ar, dark: dark);
          await t.pump(const Duration(milliseconds: 300));
          expect(t.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('student takes an exam end to end', (t) async {
    final s = await host(t, 's1', const ExamsScreen(studentId: 's1'), ar: false);
    expect(s.attemptOf('e22', 's1'), isNull);
    await t.tap(find.text('Monthly: Circulation & Respiration'));
    await t.pumpAndSettle();
    await t.tap(find.text('Start exam'));
    await t.pumpAndSettle();
    // answer first question (option A) then go next repeatedly
    for (var i = 0; i < 6; i++) {
      final opt = find.text('A');
      if (opt.evaluate().isNotEmpty) await t.tap(opt.first);
      await t.pump();
      final next = find.text('Next');
      if (next.evaluate().isNotEmpty) {
        await t.tap(next);
        await t.pumpAndSettle();
      }
    }
    // last Qs are written - type something
    final field = find.byType(TextField);
    if (field.evaluate().isNotEmpty) await t.enterText(field.first, 'My answer');
    await t.tap(find.text('Submit'));
    await t.pumpAndSettle();
    await t.tap(find.text('Submit').last);
    await t.pumpAndSettle();
    final a = s.attemptOf('e22', 's1');
    expect(a, isNotNull);
    expect(a!.graded, isFalse); // has written questions
    expect(find.textContaining('Answer review'), findsOneWidget);
    expect(t.takeException(), isNull);

    // teacher grades it
    s.login(s.user('t1'));
    s.gradeWritten(a, 5);
    expect(a.graded, isTrue);
    expect(a.score, a.mcqScore + 5);
  });

  testWidgets('cart and checkout', (t) async {
    final s = await host(t, 'p1', const StoreScreen(), ar: true);
    s.addToCart('b2');
    s.addToCart('b2');
    s.addToCart('b6');
    expect(s.cartCount, 3);
    final before = s.books.firstWhere((b) => b.id == 'b2').stock;
    final o = s.placeOrder(PayMethod.cash, 'Cairo');
    expect(o.total, 135 * 2 + 70);
    expect(s.books.firstWhere((b) => b.id == 'b2').stock, before - 2);
    expect(s.cart, isEmpty);
    expect(s.myOrders.first.id, o.id);
  });

  testWidgets('attendance + stats', (t) async {
    final s = await host(t, 't1', const TeacherAttendanceScreen(), ar: false);
    final today = DateTime.now();
    s.markAttendance('s1', today, AttStatus.absent);
    expect(s.attendanceOn('s1', today), AttStatus.absent);
    final st = s.attendanceStats('s1');
    expect(st.absent, greaterThan(0));
    expect(st.pct, lessThan(1));
  });

  testWidgets('homework submit and grade', (t) async {
    final s = await host(t, 's1', const HomeworkScreen(studentId: 's1'), ar: false);
    s.submitHomework('h22', 's1', 'done');
    final sub = s.submissionOf('h22', 's1')!;
    s.gradeSubmission(sub, 14, 'nice');
    expect(sub.mark, 14);
    expect(s.pendingHomeworkCount('s1'), 1);
  });
}
