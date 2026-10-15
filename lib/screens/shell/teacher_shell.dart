import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../common/announcements_screen.dart';
import '../common/lessons_screen.dart';
import '../common/materials_screen.dart';
import '../common/more_screen.dart';
import '../common/store_screen.dart';
import '../common/tickets_screen.dart';
import '../teacher/students_screen.dart';
import '../teacher/teacher_attendance.dart';
import '../teacher/teacher_exams.dart';
import '../teacher/teacher_home.dart';
import '../teacher/teacher_homework.dart';
import '../teacher/teacher_subscriptions.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = <Widget>[
      TeacherHome(onTab: (i) => setState(() => _index = i)),
      const TeacherAttendanceScreen(),
      const TeacherExamsScreen(),
      const TeacherHomeworkScreen(),
      MoreScreen(entries: [
        MenuEntry(Icons.play_circle_rounded, AppColors.primary, 'دروس الفيديو', 'Video lessons',
            () => const LessonsScreen()),
        MenuEntry(Icons.workspace_premium_rounded, AppColors.amber, 'الاشتراكات والأكواد', 'Subscriptions & codes',
            () => const TeacherSubscriptionsScreen()),
        MenuEntry(Icons.groups_rounded, AppColors.violet, 'الطلاب', 'Students',
            () => const StudentsScreen()),
        MenuEntry(Icons.folder_copy_rounded, AppColors.primary, 'المواد التعليمية', 'Study materials',
            () => const MaterialsScreen()),
        MenuEntry(Icons.storefront_rounded, AppColors.rose, 'المتجر', 'Store',
            () => const StoreScreen()),
        MenuEntry(Icons.receipt_long_rounded, AppColors.amber, 'طلبات المتجر', 'Store orders',
            () => const OrdersScreen(), badge: s.orders.where((o) => o.status.index == 0).length),
        MenuEntry(Icons.support_agent_rounded, AppColors.coral, 'تذاكر الدعم', 'Support tickets',
            () => const TicketsScreen(), badge: s.openTicketCount),
        MenuEntry(Icons.campaign_rounded, AppColors.sky, 'الإعلانات', 'Announcements',
            () => const AnnouncementsScreen()),
      ]),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: context.tr('الرئيسية', 'Home')),
          NavigationDestination(
              icon: const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check_rounded),
              label: context.tr('الحضور', 'Attendance')),
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
