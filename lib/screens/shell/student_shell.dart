import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../common/announcements_screen.dart';
import '../common/attendance_screen.dart';
import '../common/exams_screen.dart';
import '../common/homework_screen.dart';
import '../common/lessons_screen.dart';
import '../common/materials_screen.dart';
import '../common/more_screen.dart';
import '../common/progress_screen.dart';
import '../common/question_bank_screen.dart';
import '../common/store_screen.dart';
import '../common/subscription_screen.dart';
import '../common/tickets_screen.dart';
import '../student/student_home.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final id = s.me!.id;
    final pages = <Widget>[
      StudentHome(onTab: (i) => setState(() => _index = i)),
      const LessonsScreen(),
      ExamsScreen(studentId: id),
      HomeworkScreen(studentId: id),
      MoreScreen(entries: [
        MenuEntry(Icons.workspace_premium_rounded, AppColors.amber, 'الاشتراك', 'Subscription',
            () => SubscriptionScreen(studentId: id)),
        MenuEntry(Icons.folder_copy_rounded, AppColors.primary, 'المواد التعليمية', 'Study materials',
            () => const MaterialsScreen()),
        MenuEntry(Icons.help_center_rounded, AppColors.sky, 'بنك الأسئلة', 'Question bank',
            () => const QuestionBankScreen()),
        MenuEntry(Icons.event_available_rounded, AppColors.leaf, 'سجل الحضور', 'Attendance',
            () => AttendanceScreen(studentId: id)),
        MenuEntry(Icons.insights_rounded, AppColors.violet, 'تقدمي الدراسي', 'My progress',
            () => ProgressScreen(studentId: id)),
        MenuEntry(Icons.storefront_rounded, AppColors.rose, 'متجر الكتب', 'Books store',
            () => const StoreScreen()),
        MenuEntry(Icons.support_agent_rounded, AppColors.coral, 'التذاكر والدعم', 'Support tickets',
            () => const TicketsScreen()),
        MenuEntry(Icons.campaign_rounded, AppColors.amber, 'الإعلانات', 'Announcements',
            () => const AnnouncementsScreen()),
        MenuEntry(Icons.notifications_rounded, AppColors.primary, 'الإشعارات', 'Notifications',
            () => const NotificationsScreen(), badge: s.unreadCount),
      ]),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: context.tr('الرئيسية', 'Home')),
          NavigationDestination(
              icon: const Icon(Icons.play_circle_outline_rounded),
              selectedIcon: const Icon(Icons.play_circle_rounded),
              label: context.tr('الدروس', 'Lessons')),
          NavigationDestination(
              icon: const Icon(Icons.quiz_outlined),
              selectedIcon: const Icon(Icons.quiz_rounded),
              label: context.tr('الامتحانات', 'Exams')),
          NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment_rounded),
              label: context.tr('الواجبات', 'Homework')),
          NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: context.tr('المزيد', 'More')),
        ],
      ),
    );
  }
}
