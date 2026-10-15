import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../common/attendance_screen.dart';
import '../common/dashboard_widgets.dart';
import '../common/exams_screen.dart';
import '../common/homework_screen.dart';
import '../common/progress_screen.dart';
import '../common/tickets_screen.dart';

class ParentHome extends StatelessWidget {
  final void Function(int tab) onTab;
  const ParentHome({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.me!;
    final kid = s.activeStudent;
    final stats = s.attendanceStats(kid.id);
    final avg = s.averageScore(kid.id);
    final pending = s.pendingHomeworkCount(kid.id);
    final today = dayOnly(DateTime.now());

    // Alerts the parent should know about.
    final alerts = <(IconData, Color, String)>[];
    final todayAtt = s.attendanceOn(kid.id, today);
    if (todayAtt == AttStatus.absent) {
      alerts.add((Icons.event_busy_rounded, AppColors.coral,
          context.tr('${kid.name.ar} غائب اليوم', '${kid.name.en} is absent today')));
    } else if (todayAtt == AttStatus.late) {
      alerts.add((Icons.schedule_rounded, AppColors.amber,
          context.tr('${kid.name.ar} تأخر اليوم', '${kid.name.en} arrived late today')));
    } else if (todayAtt == AttStatus.present) {
      alerts.add((Icons.check_circle_rounded, AppColors.leaf,
          context.tr('${kid.name.ar} حضر اليوم', '${kid.name.en} attended today')));
    }
    if (stats.pct < 0.85) {
      alerts.add((Icons.warning_amber_rounded, AppColors.coral,
          context.tr('نسبة الحضور ${(stats.pct * 100).round()}% - أقل من المطلوب', 'Attendance ${(stats.pct * 100).round()}% - below target')));
    }
    for (final h in s.homeworksOfGrade(kid.grade)) {
      if (s.submissionOf(h.id, kid.id) == null &&
          !dayOnly(h.due).isBefore(today) &&
          dayOnly(h.due).difference(today).inDays <= 1) {
        alerts.add((Icons.assignment_late_rounded, AppColors.amber,
            context.tr('واجب "${h.title.ar}" موعده ${relativeDay(context, h.due)}', 'Homework "${h.title.en}" is due ${relativeDay(context, h.due).toLowerCase()}')));
      }
    }
    for (final e in s.examsOfGrade(kid.grade)) {
      if (s.attemptOf(e.id, kid.id) == null && dayOnly(e.date) == today) {
        alerts.add((Icons.quiz_rounded, AppColors.violet,
            context.tr('امتحان "${e.title.ar}" اليوم', 'Exam "${e.title.en}" is today')));
      }
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            colors: const [Color(0xFF176B8A), Color(0xFF0B4A63)],
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                ]),
                const SizedBox(height: 16),
                if (me.childIds.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final c in s.children)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: GestureDetector(
                            onTap: () => s.selectChild(c.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                              decoration: BoxDecoration(
                                color: c.id == kid.id
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(children: [
                                Avatar(c.name.initialOf(context), c.color, radius: 18),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name.of(context),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: c.id == kid.id
                                                ? AppColors.ink
                                                : Colors.white)),
                                    Text(gradeName(context, c.grade),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: c.id == kid.id
                                                ? AppColors.muted
                                                : Colors.white70)),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  )
                else
                  Row(children: [
                    Avatar(kid.name.initialOf(context), kid.color, radius: 20),
                    const SizedBox(width: 10),
                    Text(kid.name.of(context),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                const SizedBox(height: 18),
                Row(children: [
                  _Stat('${(stats.pct * 100).round()}%', context.tr('الحضور', 'Attendance'),
                      () => onTab(2)),
                  _Stat(avg == null ? '--' : '${(avg * 100).round()}%',
                      context.tr('متوسط الدرجات', 'Avg. score'), () => onTab(1)),
                  _Stat('$pending', context.tr('واجبات', 'Homework'),
                      () => go(context, HomeworkScreen(studentId: kid.id))),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(context.tr('تنبيهات اليوم', "Today's alerts")),
                if (alerts.isEmpty)
                  AppCard(
                    child: Row(children: [
                      const IconBadge(Icons.verified_rounded, AppColors.leaf),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.tr('لا توجد تنبيهات. كل شيء على ما يرام ✅', 'No alerts. All good ✅'))),
                    ]),
                  ),
                for (final a in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        IconBadge(a.$1, a.$2, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(a.$3,
                                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4))),
                      ]),
                    ),
                  ),
                SectionHeader(context.tr('الوصول السريع', 'Quick access')),
                QuickActionGrid([
                  QuickAction(Icons.event_available_rounded, AppColors.leaf, 'الحضور', 'Attendance', () => onTab(2)),
                  QuickAction(Icons.insights_rounded, AppColors.violet, 'تقرير الأداء', 'Report', () => onTab(1)),
                  QuickAction(Icons.quiz_rounded, AppColors.sky, 'الامتحانات', 'Exams',
                      () => go(context, ExamsScreen(studentId: kid.id))),
                  QuickAction(Icons.assignment_rounded, AppColors.amber, 'الواجبات', 'Homework',
                      () => go(context, HomeworkScreen(studentId: kid.id))),
                  QuickAction(Icons.storefront_rounded, AppColors.rose, 'المتجر', 'Store', () => onTab(3)),
                  QuickAction(Icons.support_agent_rounded, AppColors.coral, 'راسل المعلمة', 'Contact',
                      () => go(context, const TicketsScreen())),
                ]),
                SectionHeader(context.tr('الحصص القادمة', 'Class schedule')),
                TodayClassesCard(grade: kid.grade),
                UpcomingList(
                  studentId: kid.id,
                  onExams: () => go(context, ExamsScreen(studentId: kid.id)),
                  onHomework: () => go(context, HomeworkScreen(studentId: kid.id)),
                ),
                AnnouncementPreview(grade: kid.grade),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => go(context, ProgressScreen(studentId: kid.id)),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(context.tr('عرض تقرير الأداء الكامل', 'View full performance report')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _Stat(this.value, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
          ]),
        ),
      ),
    );
  }
}

/// Wrapper that keeps the parent's tab pages in sync with the selected child.
class ChildPage extends StatelessWidget {
  final Widget Function(String studentId) builder;
  const ChildPage(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.select<AppState, String>((s) => s.activeStudentId);
    return KeyedSubtree(key: ValueKey(id), child: builder(id));
  }
}

String attendanceTitle(BuildContext c) => c.tr('الحضور', 'Attendance');

Widget buildAttendancePage(String id) => AttendanceScreen(studentId: id);
Widget buildProgressPage(String id) => ProgressScreen(studentId: id);
