import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../common/attendance_screen.dart';
import '../common/exams_screen.dart';
import '../common/progress_screen.dart';

/// Student roster with attendance and score snapshots for Dr. Rashia.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  int? _grade;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.students.where((u) {
      if (_grade != null && u.grade != _grade) return false;
      if (_q.isNotEmpty &&
          !(u.name.ar.contains(_q) || u.name.en.toLowerCase().contains(_q.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('الطلاب', 'Students'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: context.tr('ابحث باسم الطالب...', 'Search by name...'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          ChipSelector<int?>(
            values: const [null, 1, 2, 3],
            selected: _grade,
            label: (g) => g == null ? context.tr('الكل', 'All') : gradeShort(context, g),
            onChanged: (g) => setState(() => _grade = g),
          ),
          const SizedBox(height: 12),
          for (final u in list)
            Builder(builder: (_) {
              final att = s.attendanceStats(u.id).pct;
              final avg = s.averageScore(u.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => showSheet(context, (_) => _StudentSheet(id: u.id)),
                  child: Row(children: [
                    Avatar(u.name.initialOf(context), u.color, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name.of(context),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${gradeShort(context, u.grade)} • ${u.section}',
                              style: TextStyle(color: context.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Pill('${(att * 100).round()}%', att >= 0.85 ? AppColors.leaf : AppColors.coral,
                            icon: Icons.event_available_rounded),
                        const SizedBox(height: 4),
                        if (avg != null)
                          Text('${(avg * 100).round()}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: scoreColor(avg),
                                  fontSize: 12)),
                      ],
                    ),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StudentSheet extends StatelessWidget {
  final String id;
  const _StudentSheet({required this.id});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final u = s.user(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Avatar(u.name.initialOf(context), u.color, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name.of(context),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('${gradeName(context, u.grade)} • ${u.section}',
                    style: TextStyle(color: context.muted)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            go(context, AttendanceScreen(studentId: id));
          },
          icon: const Icon(Icons.event_available_rounded),
          label: Text(context.tr('سجل الحضور', 'Attendance record')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            go(context, ProgressScreen(studentId: id));
          },
          icon: const Icon(Icons.insights_rounded),
          label: Text(context.tr('تقرير الأداء', 'Performance report')),
        ),
      ],
    );
  }
}
