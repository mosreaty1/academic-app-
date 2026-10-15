import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

/// Attendance overview + month calendar for one student.
/// Used by the student app and by the parent monitor.
class AttendanceScreen extends StatefulWidget {
  final String studentId;
  const AttendanceScreen({super.key, required this.studentId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.user(widget.studentId);
    final stats = s.attendanceStats(widget.studentId);
    final isParent = s.me!.role != UserRole.student;
    final pct = stats.pct;
    final ringColor = pct >= 0.9
        ? AppColors.leaf
        : pct >= 0.75
            ? AppColors.amber
            : AppColors.coral;

    final records = s.attendanceOf(widget.studentId).entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final incidents = records
        .where((e) => e.value != AttStatus.present)
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isParent
            ? context.tr('حضور ${st.name.ar}', '${st.name.en} • Attendance')
            : context.tr('سجل الحضور', 'My attendance')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          AppCard(
            child: Row(
              children: [
                ProgressRing(
                  value: pct,
                  color: ringColor,
                  size: 104,
                  stroke: 11,
                  child: Text('${(pct * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('نسبة الحضور', 'Attendance rate'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                          pct >= 0.9
                              ? context.tr('ممتاز! استمر على الانتظام', 'Excellent! Keep it up')
                              : pct >= 0.75
                                  ? context.tr('جيد، حاول تقليل الغياب', 'Good, try to reduce absences')
                                  : context.tr('تنبيه: نسبة الحضور منخفضة', 'Warning: low attendance'),
                          style: TextStyle(color: context.muted, fontSize: 14)),
                      const SizedBox(height: 12),
                      Text(
                          context.tr('${stats.total} يوم دراسي مسجل',
                              '${stats.total} school days recorded'),
                          style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final t in AttStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CountTile(
                      label: attLabel(context, t),
                      color: attColor(t),
                      value: switch (t) {
                        AttStatus.present => stats.present,
                        AttStatus.absent => stats.absent,
                        AttStatus.late => stats.late,
                        AttStatus.excused => stats.excused,
                      },
                    ),
                  ),
                ),
            ],
          ),
          SectionHeader(context.tr('التقويم', 'Calendar')),
          _MonthCalendar(
            month: _month,
            studentId: widget.studentId,
            onPrev: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1)),
            onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1)),
          ),
          SectionHeader(context.tr('آخر الملاحظات', 'Recent notes')),
          if (incidents.isEmpty)
            AppCard(
              child: Row(children: [
                const IconBadge(Icons.verified_rounded, AppColors.leaf),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(context.tr('لا يوجد غياب أو تأخير. أحسنت!',
                        'No absences or late arrivals. Well done!')))
              ]),
            )
          else
            for (final e in incidents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconBadge(
                          e.value == AttStatus.late
                              ? Icons.schedule_rounded
                              : e.value == AttStatus.excused
                                  ? Icons.medical_services_rounded
                                  : Icons.event_busy_rounded,
                          attColor(e.value),
                          size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(fmtDateFull(context, DateTime.parse(e.key)),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Pill(attLabel(context, e.value), attColor(e.value)),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          if (stats.absent > 0)
            OutlinedButton.icon(
              onPressed: () => toast(
                  context,
                  context.tr('افتح التذاكر لإرسال عذر غياب',
                      'Open Tickets to submit an absence excuse')),
              icon: const Icon(Icons.edit_document),
              label: Text(context.tr('تقديم عذر غياب', 'Submit absence excuse')),
            ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  const _CountTile(
      {required this.label, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      radius: 16,
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

String _shortDay(BuildContext c, int weekday) {
  const ar = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (c.isAr ? ar : en)[weekday - 1];
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final String studentId;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthCalendar(
      {required this.month,
      required this.studentId,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday % 7; // Sunday first
    final today = dayOnly(DateTime.now());
    final names = [7, 1, 2, 3, 4, 5, 6]; // Sun..Sat
    final isNext = DateTime(month.year, month.month + 1).isAfter(DateTime(today.year, today.month));

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: Center(
                  child: Text(
                      '${fmtDate(context, first).split(' ').last} ${month.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ),
              IconButton(
                  onPressed: isNext ? null : onNext,
                  icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final w in names)
                Expanded(
                  child: Center(
                    child: Text(_shortDay(context, w),
                        style: TextStyle(
                            color: context.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++)
                _cell(context, s, DateTime(month.year, month.month, d), today),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final t in AttStatus.values)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: attColor(t), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(attLabel(context, t),
                      style: TextStyle(color: context.muted, fontSize: 12)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, AppState s, DateTime d, DateTime today) {
    final st = s.attendanceOn(studentId, d);
    final weekend = d.weekday == DateTime.friday || d.weekday == DateTime.saturday;
    final isToday = d == today;
    final color = st == null ? null : attColor(st);
    return Container(
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: context.cs.primary, width: 1.8) : null,
      ),
      child: Center(
        child: Text('${d.day}',
            style: TextStyle(
                fontWeight: st == null ? FontWeight.w400 : FontWeight.w700,
                color: color ?? (weekend ? context.muted.withValues(alpha: 0.5) : context.ink),
                fontSize: 14)),
      ),
    );
  }
}
