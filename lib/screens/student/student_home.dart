import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../common/attendance_screen.dart';
import '../common/dashboard_widgets.dart';
import '../common/progress_screen.dart';
import '../common/question_bank_screen.dart';
import '../common/store_screen.dart';
import '../common/tickets_screen.dart';

class StudentHome extends StatelessWidget {
  final void Function(int tab) onTab;
  const StudentHome({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.me!;
    final stats = s.attendanceStats(me.id);
    final avg = s.averageScore(me.id);
    final pending = s.pendingHomeworkCount(me.id);
    final today = dayOnly(DateTime.now());
    final openExams = s
        .examsOfGrade(me.grade)
        .where((e) => dayOnly(e.date) == today && s.attemptOf(e.id, me.id) == null)
        .toList();

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
                  Avatar(me.name.initialOf(context), me.color, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting(context),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13)),
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
                const SizedBox(height: 18),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Chip(Icons.school_rounded, gradeName(context, me.grade)),
                  _Chip(Icons.class_rounded, '${context.tr('فصل', 'Class')} ${me.section}'),
                ]),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _HeroStat(
                        value: '${(stats.pct * 100).round()}%',
                        label: context.tr('الحضور', 'Attendance'),
                        onTap: () => go(context, AttendanceScreen(studentId: me.id))),
                    _HeroStat(
                        value: avg == null ? '--' : '${(avg * 100).round()}%',
                        label: context.tr('متوسط الدرجات', 'Avg. score'),
                        onTap: () => go(context, ProgressScreen(studentId: me.id))),
                    _HeroStat(
                        value: '$pending',
                        label: context.tr('واجبات مطلوبة', 'Homework due'),
                        onTap: () => onTab(2)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in openExams)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AppCard(
                      onTap: () => onTab(1),
                      gradient: const LinearGradient(
                          colors: [AppColors.violet, Color(0xFF5A3FA0)]),
                      border: false,
                      child: Row(children: [
                        const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('امتحان متاح الآن', 'Exam available now'),
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12)),
                              Text(e.title.of(context),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ]),
                    ),
                  ),
                SectionHeader(context.tr('الوصول السريع', 'Quick access')),
                QuickActionGrid([
                  QuickAction(Icons.quiz_rounded, AppColors.violet, 'الامتحانات', 'Exams', () => onTab(1)),
                  QuickAction(Icons.help_center_rounded, AppColors.sky, 'بنك الأسئلة', 'Question bank',
                      () => go(context, const QuestionBankScreen())),
                  QuickAction(Icons.assignment_rounded, AppColors.amber, 'الواجبات', 'Homework', () => onTab(2)),
                  QuickAction(Icons.folder_copy_rounded, AppColors.primary, 'المواد', 'Materials', () => onTab(3)),
                  QuickAction(Icons.event_available_rounded, AppColors.leaf, 'الحضور', 'Attendance',
                      () => go(context, AttendanceScreen(studentId: me.id))),
                  QuickAction(Icons.storefront_rounded, AppColors.rose, 'المتجر', 'Store',
                      () => go(context, const StoreScreen())),
                  QuickAction(Icons.support_agent_rounded, AppColors.coral, 'التذاكر', 'Tickets',
                      () => go(context, const TicketsScreen())),
                  QuickAction(Icons.insights_rounded, AppColors.violet, 'تقدمي', 'Progress',
                      () => go(context, ProgressScreen(studentId: me.id))),
                ]),
                const SizedBox(height: 8),
                SectionHeader(context.tr('جدولك', 'Your schedule')),
                TodayClassesCard(grade: me.grade),
                UpcomingList(
                  studentId: me.id,
                  onExams: () => onTab(1),
                  onHomework: () => onTab(2),
                ),
                AnnouncementPreview(grade: me.grade),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _HeroStat({required this.value, required this.label, required this.onTap});

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
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
          ]),
        ),
      ),
    );
  }
}
