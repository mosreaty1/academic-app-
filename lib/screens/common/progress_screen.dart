import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import 'exams_screen.dart';

/// Academic performance report for one student (used by student + parent).
class ProgressScreen extends StatelessWidget {
  final String studentId;
  const ProgressScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.user(studentId);
    final isParent = s.me!.role != UserRole.student;
    final attempts = s.attemptsOfStudent(studentId).where((a) => a.graded).toList();
    final avg = s.averageScore(studentId);
    final mastery = s.chapterMastery(studentId);
    final stats = s.attendanceStats(studentId);

    final hwGraded = s
        .homeworksOfGrade(st.grade)
        .map((h) => (h, s.submissionOf(h.id, studentId)))
        .where((e) => e.$2?.mark != null)
        .toList();
    final hwAvg = hwGraded.isEmpty
        ? null
        : hwGraded.fold<double>(0, (a, e) => a + e.$2!.mark! / e.$1.maxMarks) /
            hwGraded.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isParent
            ? context.tr('تقرير ${st.name.ar}', '${st.name.en} • Report')
            : context.tr('تقدمي الدراسي', 'My progress')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.grade_rounded,
                  color: AppColors.violet,
                  value: avg == null ? '--' : '${(avg * 100).round()}%',
                  label: context.tr('متوسط الامتحانات', 'Exam average'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.amber,
                  value: hwAvg == null ? '--' : '${(hwAvg * 100).round()}%',
                  label: context.tr('متوسط الواجبات', 'Homework average'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: Icons.event_available_rounded,
                  color: AppColors.leaf,
                  value: '${(stats.pct * 100).round()}%',
                  label: context.tr('الحضور', 'Attendance'),
                ),
              ),
            ],
          ),
          SectionHeader(context.tr('نتائج الامتحانات', 'Exam results')),
          AppCard(
            child: attempts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                        child: Text(context.tr('لا توجد نتائج بعد', 'No results yet'),
                            style: TextStyle(color: context.muted))),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final a in attempts)
                              _Bar(
                                value: a.percent,
                                label: s.exam(a.examId).title.of(context),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          SectionHeader(context.tr('إتقان الفصول (التدريب)', 'Chapter mastery (practice)')),
          AppCard(
            child: mastery.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                          context.tr('حل أسئلة من بنك الأسئلة لقياس مستواك',
                              'Practice with the question bank to measure your level'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.muted)),
                    ),
                  )
                : Column(
                    children: [
                      for (final e in mastery.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: _MasteryRow(
                            label: s.questions
                                .firstWhere((q) => q.chapter.en == e.key)
                                .chapter
                                .of(context),
                            value: e.value,
                          ),
                        ),
                    ],
                  ),
          ),
          if (mastery.values.any((v) => v < 0.6)) ...[
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.amber.withValues(alpha: 0.12),
              child: Row(children: [
                const Icon(Icons.tips_and_updates_rounded, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      context.tr('ننصح بمراجعة الفصول ذات النسبة المنخفضة وحل المزيد من الأسئلة عليها.',
                          'We recommend revising the low-scoring chapters and practising more questions on them.'),
                      style: const TextStyle(height: 1.5)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final String label;
  const _Bar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(value);
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${(value * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 90 * value + 6,
            width: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.55)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  final String label;
  final double value;
  const _MasteryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(value);
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
          Text('${(value * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: color,
            backgroundColor: context.line,
          ),
        ),
      ],
    );
  }
}
