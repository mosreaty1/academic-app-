import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../common/attendance_screen.dart';
import '../common/exams_screen.dart';
import '../common/progress_screen.dart';
import '../common/student_id_card.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSheet(context, (_) => const _AddStudentForm()),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.tr('إضافة طالب', 'Add student')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
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
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${u.code} • ${gradeShort(context, u.grade)}',
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
                                  fontWeight: FontWeight.w700,
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
        StudentIdCard(student: u),
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

class _AddStudentForm extends StatefulWidget {
  const _AddStudentForm();

  @override
  State<_AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<_AddStudentForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _grade = 1;
  String _section = 'A';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _newPassword() {
    final n = DateTime.now().microsecondsSinceEpoch % 900000 + 100000;
    return '$n';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.tr('اكتب اسم الطالب', 'Enter the student name'));
      return;
    }
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    final password = _newPassword();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final u = await s.addStudent(
        name: Bi(name, name),
        grade: _grade,
        section: _section,
        parentPhone: _phone.text.trim(),
        password: password,
      );
      if (!mounted) return;
      nav.pop();
      showDialog<void>(
        context: nav.context,
        builder: (ctx) => _CredentialsDialog(student: u, password: password),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.tr('تعذر إنشاء الحساب. حاول مرة أخرى', 'Could not create the account. Try again');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('إضافة طالب جديد', 'Add a new student'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(context.tr('سيتم إنشاء كود الطالب وكلمة المرور تلقائياً', 'The Student ID and password are generated automatically'),
            style: TextStyle(color: context.muted, fontSize: 12.5)),
        const SizedBox(height: 14),
        LabeledField(context.tr('اسم الطالب', 'Student name'), _name),
        LabeledField(context.tr('موبايل ولي الأمر (للربط)', 'Parent phone (to link)'), _phone,
            keyboard: TextInputType.phone),
        ChipSelector<int>(
          values: const [1, 2, 3],
          selected: _grade,
          label: (g) => gradeTiny(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 10),
        ChipSelector<String>(
          values: const ['A', 'B', 'C'],
          selected: _section,
          label: (x) => '${context.tr('فصل', 'Class')} $x',
          onChanged: (x) => setState(() => _section = x),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!,
                style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(context.tr('إنشاء الحساب', 'Create account')),
        ),
      ],
    );
  }
}

class _CredentialsDialog extends StatelessWidget {
  final UserProfile student;
  final String password;
  const _CredentialsDialog({required this.student, required this.password});

  @override
  Widget build(BuildContext context) {
    final text = context.tr(
        'أكاديمية د. راشيا\nالطالب: ${student.name.ar}\nكود الطالب: ${student.code}\nكلمة المرور: $password',
        'Dr. Rashia Academy\nStudent: ${student.name.en}\nStudent ID: ${student.code}\nPassword: $password');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(context.tr('تم إنشاء الحساب','Account created'),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.name.of(context), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _row(context, context.tr('كود الطالب', 'Student ID'), student.code),
          _row(context, context.tr('كلمة المرور', 'Password'), password),
          const SizedBox(height: 10),
          Text(
              context.tr('احتفظ بكلمة المرور الآن، لن تظهر مرة أخرى.', 'Save the password now - it will not be shown again.'),
              style: TextStyle(color: context.muted, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            toast(context, context.tr('تم النسخ', 'Copied'));
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(context.tr('نسخ', 'Copy')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('تم', 'Done')),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text('$k: ', style: TextStyle(color: context.muted)),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(v,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ]),
      );
}
