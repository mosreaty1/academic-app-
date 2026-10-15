import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

/// Roll call: Dr. Rashia marks each student's attendance per grade and day.
class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  int _grade = 2;
  DateTime _date = dayOnly(DateTime.now());

  bool _isSchoolDay(DateTime d) =>
      d.weekday != DateTime.friday && d.weekday != DateTime.saturday;

  void _shift(int dir) {
    var d = _date;
    do {
      d = d.add(Duration(days: dir));
    } while (!_isSchoolDay(d));
    if (d.isAfter(dayOnly(DateTime.now()))) return;
    setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final students = s.studentsOfGrade(_grade);
    var p = 0, a = 0, l = 0, e = 0, un = 0;
    for (final st in students) {
      switch (s.attendanceOn(st.id, _date)) {
        case AttStatus.present:
          p++;
        case AttStatus.absent:
          a++;
        case AttStatus.late:
          l++;
        case AttStatus.excused:
          e++;
        case null:
          un++;
      }
    }
    final isToday = _date == dayOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('تسجيل الحضور', 'Take attendance'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              ChipSelector<int>(
                values: const [1, 2, 3],
                selected: _grade,
                label: (g) => gradeTiny(context, g),
                onChanged: (g) => setState(() => _grade = g),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(
                    child: Column(children: [
                      Text(fmtDateFull(context, _date),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (isToday)
                        Text(context.tr('اليوم', 'Today'),
                            style: TextStyle(color: context.brand, fontSize: 12)),
                    ]),
                  ),
                  IconButton(
                      onPressed: isToday ? null : () => _shift(1),
                      icon: const Icon(Icons.chevron_right_rounded)),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _mini(context, p, AttStatus.present),
                _mini(context, a, AttStatus.absent),
                _mini(context, l, AttStatus.late),
                _mini(context, e, AttStatus.excused),
              ]),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (final st in students)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        Row(children: [
                          Avatar(st.name.initialOf(context), st.color, radius: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(st.name.of(context),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(st.section,
                              style: TextStyle(color: context.muted, fontSize: 12)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          for (final t in AttStatus.values)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _StatusBtn(
                                  status: t,
                                  selected: s.attendanceOn(st.id, _date) == t,
                                  onTap: () => s.markAttendance(st.id, _date, t),
                                ),
                              ),
                            ),
                        ]),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                  color: context.card,
                  border: Border(top: BorderSide(color: context.line))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      for (final st in students) {
                        if (s.attendanceOn(st.id, _date) == null) {
                          s.markAttendance(st.id, _date, AttStatus.present);
                        }
                      }
                    },
                    child: Text(context.tr('الباقي حاضر', 'Rest present')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (un > 0) {
                        toast(context, context.tr('بقي $un طالب بدون تسجيل', '$un student(s) not marked yet'));
                        return;
                      }
                      toast(
                          context,
                          context.tr('تم الحفظ وإبلاغ أولياء أمور الغائبين ($a)',
                              'Saved. Parents of absent students notified ($a)'));
                    },
                    child: Text(context.tr('حفظ وإرسال', 'Save & notify')),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(BuildContext context, int n, AttStatus t) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: attColor(t).withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text('$n',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: attColor(t))),
          Text(attLabel(context, t),
              style: TextStyle(fontSize: 12, color: attColor(t))),
        ]),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final AttStatus status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusBtn(
      {required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = attColor(status);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c : context.line),
        ),
        child: Center(
          child: Text(attLabel(context, status),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.muted)),
        ),
      ),
    );
  }
}
