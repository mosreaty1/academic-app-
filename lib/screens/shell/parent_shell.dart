import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../common/announcements_screen.dart';
import '../common/exams_screen.dart';
import '../common/homework_screen.dart';
import '../common/more_screen.dart';
import '../common/store_screen.dart';
import '../common/tickets_screen.dart';
import '../parent/parent_home.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = <Widget>[
      ParentHome(onTab: (i) => setState(() => _index = i)),
      ChildPage(buildProgressPage),
      ChildPage(buildAttendancePage),
      const StoreScreen(),
      MoreScreen(entries: [
        MenuEntry(Icons.quiz_rounded, AppColors.violet, 'امتحانات الابن', 'Exams & results',
            () => ExamsScreen(studentId: s.activeStudentId)),
        MenuEntry(Icons.assignment_rounded, AppColors.amber, 'الواجبات', 'Homework',
            () => HomeworkScreen(studentId: s.activeStudentId)),
        MenuEntry(Icons.support_agent_rounded, AppColors.coral, 'التواصل مع المعلمة', 'Contact the teacher',
            () => const TicketsScreen()),
        MenuEntry(Icons.campaign_rounded, AppColors.sky, 'الإعلانات', 'Announcements',
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
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: context.tr('الأداء', 'Progress')),
          NavigationDestination(
              icon: const Icon(Icons.event_available_outlined),
              selectedIcon: const Icon(Icons.event_available_rounded),
              label: context.tr('الحضور', 'Attendance')),
          NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront_rounded),
              label: context.tr('المتجر', 'Store')),
          NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: context.tr('المزيد', 'More')),
        ],
      ),
    );
  }
}
