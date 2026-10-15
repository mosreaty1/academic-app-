import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../common/attendance_screen.dart';
import '../common/dashboard_widgets.dart';
import '../common/lessons_screen.dart';
import '../../models/models.dart';
import '../common/progress_screen.dart';
import '../common/question_bank_screen.dart';
import '../common/store_screen.dart';
import '../common/subscription_screen.dart';
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
    // Returning students resume the lesson they were watching; new students
    // get the first lesson they can open.
    final watchable =
        s.lessonsOfGrade(me.grade).where((l) => s.canWatch(me.id, l)).toList();
    Lesson? cont;
    for (final l in watchable) {
      final p = s.progressOf(me.id, l.id);
      if (p > 0 && p < 0.9) {
        cont = l;
        break;
      }
    }
    for (final l in watchable) {
      if (cont != null) break;
      if (s.progressOf(me.id, l.id) < 0.9) cont = l;
    }
    final openExams = s
        .examsOfGrade(me.grade)
        .where((e) => dayOnly(e.date) == today && s.attemptOf(e.id, me.id) == null)
        .toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                                fontSize: 14)),
                        Text(me.name.of(context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                ]),
                const SizedBox(height: 20),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Chip(Icons.school_rounded, gradeName(context, me.grade)),
                  _Chip(Icons.class_rounded, '${context.tr('فصل', 'Class')} ${me.section}'),
                ]),
                const SizedBox(height: 20),
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
                        onTap: () => onTab(3)),
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
                      onTap: () => onTab(2),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1B3A32), Color(0xFF0E241F)]),
                      border: false,
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(13)),
                          child: const Icon(Icons.alarm_on_rounded, color: AppColors.gold, size: 24),
                        ),
                        const SizedBox(width: 16),
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ]),
                    ),
                  ),
                if (cont != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AppCard(
                      onTap: () => go(context, LessonPlayerScreen(lessonId: cont!.id, studentId: me.id)),
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: context.brandSoft,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.play_arrow_rounded, color: context.brand, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  s.progressOf(me.id, cont.id) > 0
                                      ? context.tr('أكمل من حيث توقفت', 'Pick up where you left off')
                                      : context.tr('ابدأ درسك التالي', 'Start your next lesson'),
                                  style: TextStyle(fontSize: 12, color: context.muted)),
                              const SizedBox(height: 4),
                              Text(cont.title.of(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: s.progressOf(me.id, cont.id),
                                  minHeight: 4,
                                  color: context.brand,
                                  backgroundColor: context.line,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.chevron_right_rounded, color: context.muted),
                      ]),
                    ),
                  ),
                if (!s.hasAccess(me.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AppCard(
                      onTap: () => go(context, SubscriptionScreen(studentId: me.id)),
                      color: AppColors.amber.withValues(alpha: context.isDark ? 0.16 : 0.12),
                      child: Row(children: [
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.amber, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('افتح كل الدروس المدفوعة', 'Unlock all premium lessons'),
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(context.tr('اشترك أو فعّل كود الاشتراك', 'Subscribe or redeem a code'),
                                  style: TextStyle(color: context.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: context.muted),
                      ]),
                    ),
                  ),
                SectionHeader(context.tr('الوصول السريع', 'Quick access')),
                QuickActionGrid([
                  QuickAction(Icons.quiz_rounded, AppColors.violet, 'الامتحانات', 'Exams', () => onTab(2)),
                  QuickAction(Icons.help_center_rounded, AppColors.sky, 'بنك الأسئلة', 'Question bank',
                      () => go(context, const QuestionBankScreen())),
                  QuickAction(Icons.assignment_rounded, AppColors.amber, 'الواجبات', 'Homework', () => onTab(3)),
                  QuickAction(Icons.play_circle_rounded, AppColors.primary, 'الدروس', 'Lessons', () => onTab(1)),
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
                  onExams: () => onTab(2),
                  onHomework: () => onTab(3),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) =>
      HeroStat(value: value, label: label, onTap: onTap);
}
