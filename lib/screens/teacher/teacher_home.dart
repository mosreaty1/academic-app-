import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../common/dashboard_widgets.dart';
import '../common/lessons_screen.dart';
import '../common/store_screen.dart';
import '../common/tickets_screen.dart';
import 'students_screen.dart';
import 'teacher_subscriptions.dart';
import 'teacher_exams.dart';

class TeacherHome extends StatelessWidget {
  final void Function(int tab) onTab;
  const TeacherHome({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.me!;
    final today = dayOnly(DateTime.now());
    final students = s.students;

    var marked = 0, present = 0;
    for (final st in students) {
      final a = s.attendanceOn(st.id, today);
      if (a != null) {
        marked++;
        if (a != AttStatus.absent) present++;
      }
    }
    final toGradeExams = s.attempts.where((a) => !a.graded).toList();
    final toGradeHw = s.submissions.where((x) => x.mark == null).toList();
    final lowAtt = students.where((u) => s.attendanceStats(u.id).pct < 0.85).toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Avatar(me.name.initialOf(context), Colors.white.withValues(alpha: 0.25), radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting(context),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                        Text(me.name.of(context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  _HeroStat('${students.length}', context.tr('طالب', 'Students'),
                      () => go(context, const StudentsScreen())),
                  _HeroStat(
                      marked == 0 ? '--' : '${(present / marked * 100).round()}%',
                      context.tr('حضور اليوم', 'Present today'),
                      () => onTab(1)),
                  _HeroStat('${toGradeExams.length + toGradeHw.length}',
                      context.tr('للتصحيح', 'To grade'), () => onTab(2)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(context.tr('إجراءات سريعة', 'Quick actions')),
                QuickActionGrid([
                  QuickAction(Icons.fact_check_rounded, AppColors.leaf, 'تسجيل الحضور', 'Attendance', () => onTab(1)),
                  QuickAction(Icons.add_task_rounded, AppColors.violet, 'امتحان جديد', 'New exam',
                      () => go(context, const CreateExamScreen())),
                  QuickAction(Icons.assignment_add, AppColors.amber, 'واجب جديد', 'Homework', () => onTab(3)),
                  QuickAction(Icons.play_circle_rounded, AppColors.primary, 'الدروس', 'Lessons',
                      () => go(context, const LessonsScreen())),
                  QuickAction(Icons.workspace_premium_rounded, AppColors.amber, 'الاشتراكات', 'Subscriptions',
                      () => go(context, const TeacherSubscriptionsScreen())),
                  QuickAction(Icons.storefront_rounded, AppColors.rose, 'المتجر', 'Store',
                      () => go(context, const StoreScreen())),
                  QuickAction(Icons.support_agent_rounded, AppColors.coral, 'التذاكر', 'Tickets',
                      () => go(context, const TicketsScreen())),
                  QuickAction(Icons.groups_rounded, AppColors.violet, 'الطلاب', 'Students',
                      () => go(context, const StudentsScreen())),
                ]),
                const SizedBox(height: 16),
                const TodayClassesCard(),
                SectionHeader(context.tr('يحتاج انتباهك', 'Needs your attention')),
                if (toGradeExams.isEmpty && toGradeHw.isEmpty && s.openTicketCount == 0 && lowAtt.isEmpty)
                  AppCard(
                    child: Row(children: [
                      const IconBadge(Icons.verified_rounded, AppColors.leaf),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.tr('كل شيء منجز',"You're all caught up"))),
                    ]),
                  ),
                if (toGradeExams.isNotEmpty)
                  _Attention(
                    icon: Icons.edit_note_rounded,
                    color: AppColors.violet,
                    title: context.tr('${toGradeExams.length} إجابات مقالية للتصحيح', '${toGradeExams.length} written exam(s) to grade'),
                    onTap: () => onTab(2),
                  ),
                if (toGradeHw.isNotEmpty)
                  _Attention(
                    icon: Icons.assignment_turned_in_rounded,
                    color: AppColors.amber,
                    title: context.tr('${toGradeHw.length} تسليمات واجبات للتصحيح', '${toGradeHw.length} homework submission(s) to grade'),
                    onTap: () => onTab(3),
                  ),
                if (s.openTicketCount > 0)
                  _Attention(
                    icon: Icons.support_agent_rounded,
                    color: AppColors.coral,
                    title: context.tr('${s.openTicketCount} تذاكر مفتوحة', '${s.openTicketCount} open ticket(s)'),
                    onTap: () => go(context, const TicketsScreen()),
                  ),
                if (lowAtt.isNotEmpty)
                  _Attention(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.sky,
                    title: context.tr('${lowAtt.length} طلاب حضورهم أقل من 85%', '${lowAtt.length} student(s) below 85% attendance'),
                    onTap: () => go(context, const StudentsScreen()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Attention extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _Attention(
      {required this.icon, required this.color, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          IconBadge(icon, color, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Icon(Icons.chevron_right_rounded, color: context.muted),
        ]),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _HeroStat(this.value, this.label, this.onTap);

  @override
  Widget build(BuildContext context) =>
      HeroStat(value: value, label: label, onTap: onTap);
}
