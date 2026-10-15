import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

class TeacherHomeworkScreen extends StatelessWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = [...s.homeworks]..sort((a, b) => b.due.compareTo(a.due));
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('الواجبات', 'Homework'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSheet(context, (_) => const _CreateHomeworkForm()),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('واجب جديد', 'New homework')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          for (final h in list)
            Builder(builder: (_) {
              final subs = s.submissionsOf(h.id);
              final roster = s.studentsOfGrade(h.grade).length;
              final toGrade = subs.where((x) => x.mark == null).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => go(context, HomeworkDetailScreen(hwId: h.id)),
                  child: Row(children: [
                    const IconBadge(Icons.assignment_rounded, AppColors.amber),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.title.of(context),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(
                              '${gradeShort(context, h.grade)} • ${context.tr('الموعد', 'Due')} ${fmtDate(context, h.due)}',
                              style: TextStyle(color: context.muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: roster == 0 ? 0 : subs.length / roster,
                              minHeight: 6,
                              color: AppColors.sky,
                              backgroundColor: context.line,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              context.tr('سلّم ${subs.length} من $roster', '${subs.length} of $roster submitted'),
                              style: TextStyle(color: context.muted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (toGrade > 0)
                      Pill(context.tr('$toGrade للتصحيح', '$toGrade to grade'), AppColors.amber),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class HomeworkDetailScreen extends StatelessWidget {
  final String hwId;
  const HomeworkDetailScreen({super.key, required this.hwId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = s.homeworks.firstWhere((x) => x.id == hwId);
    final roster = s.studentsOfGrade(h.grade);
    return Scaffold(
      appBar: AppBar(title: Text(h.title.of(context))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 6, children: [
                  Pill(gradeShort(context, h.grade), AppColors.primary),
                  Pill(h.chapter.of(context), AppColors.sky),
                  Pill('${context.tr('الموعد', 'Due')} ${fmtDate(context, h.due)}', AppColors.amber),
                  Pill('${h.maxMarks} ${context.tr('درجة', 'marks')}', AppColors.violet),
                ]),
                const SizedBox(height: 10),
                Text(h.description.of(context), style: const TextStyle(height: 1.55)),
              ],
            ),
          ),
          SectionHeader(context.tr('تسليمات الطلاب', 'Student submissions')),
          for (final st in roster)
            Builder(builder: (_) {
              final sub = s.submissionOf(h.id, st.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: sub == null
                      ? null
                      : () => showSheet(context, (_) => _GradeSheet(hw: h, sub: sub)),
                  child: Row(children: [
                    Avatar(st.name.initialOf(context), st.color, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(st.name.of(context),
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (sub == null)
                      Pill(context.tr('لم يسلّم', 'Missing'), AppColors.coral)
                    else if (sub.mark == null)
                      Pill(context.tr('صحّح', 'Grade'), AppColors.amber, icon: Icons.edit_rounded)
                    else
                      Text('${sub.mark}/${h.maxMarks}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.leaf)),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _GradeSheet extends StatefulWidget {
  final Homework hw;
  final Submission sub;
  const _GradeSheet({required this.hw, required this.sub});

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late final _mark = TextEditingController(text: widget.sub.mark?.toString() ?? '');
  late final _fb = TextEditingController(text: widget.sub.feedback);

  @override
  void dispose() {
    _mark.dispose();
    _fb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final st = s.user(widget.sub.studentId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(st.name.of(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(timeAgo(context, widget.sub.at), style: TextStyle(color: context.muted)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.brandSoft, borderRadius: BorderRadius.circular(14)),
          child: Text(widget.sub.text, style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 16),
        LabeledField(context.tr('الدرجة (من ${widget.hw.maxMarks})', 'Mark (out of ${widget.hw.maxMarks})'),
            _mark, keyboard: TextInputType.number),
        LabeledField(context.tr('تعليق للطالب', 'Feedback'), _fb, maxLines: 2),
        FilledButton(
          onPressed: () {
            final m = int.tryParse(_mark.text);
            if (m == null) {
              toast(context, context.tr('أدخل الدرجة', 'Enter a mark'));
              return;
            }
            s.gradeSubmission(widget.sub, m.clamp(0, widget.hw.maxMarks), _fb.text.trim());
            Navigator.pop(context);
            toast(context, context.tr('تم حفظ الدرجة', 'Mark saved'));
          },
          child: Text(context.tr('حفظ', 'Save')),
        ),
      ],
    );
  }
}

class _CreateHomeworkForm extends StatefulWidget {
  const _CreateHomeworkForm();

  @override
  State<_CreateHomeworkForm> createState() => _CreateHomeworkFormState();
}

class _CreateHomeworkFormState extends State<_CreateHomeworkForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _marks = TextEditingController(text: '10');
  int _grade = 2;
  Bi? _chapter;
  DateTime _due = dayOnly(DateTime.now()).add(const Duration(days: 3));

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _marks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final chapters = s.chaptersOf(_grade);
    if (_chapter == null || !chapters.any((c) => c.en == _chapter!.en)) {
      _chapter = chapters.isEmpty ? null : chapters.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('واجب جديد', 'New homework'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        LabeledField(context.tr('العنوان', 'Title'), _title),
        LabeledField(context.tr('التعليمات', 'Instructions'), _desc, maxLines: 3),
        ChipSelector<int>(
          values: const [1, 2, 3],
          selected: _grade,
          label: (g) => gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 10),
        if (chapters.isNotEmpty)
          ChipSelector<String>(
            values: chapters.map((c) => c.en).toList(),
            selected: _chapter!.en,
            label: (en) => chapters.firstWhere((c) => c.en == en).of(context),
            onChanged: (en) =>
                setState(() => _chapter = chapters.firstWhere((c) => c.en == en)),
          ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _due,
                  firstDate: dayOnly(DateTime.now()),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _due = d);
              },
              icon: const Icon(Icons.event_rounded),
              label: Text(fmtDateYear(context, _due)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _marks,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: context.tr('درجة', 'pts')),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final t = _title.text.trim();
            final d = _desc.text.trim();
            if (t.isEmpty || _chapter == null) {
              toast(context, context.tr('اكتب عنوان الواجب', 'Enter a title'));
              return;
            }
            s.addHomework(Homework(
              id: 'h${DateTime.now().microsecondsSinceEpoch}',
              title: Bi(t, t),
              description: Bi(d, d),
              grade: _grade,
              chapter: _chapter!,
              due: _due,
              maxMarks: int.tryParse(_marks.text) ?? 10,
            ));
            Navigator.pop(context);
            toast(context, context.tr('تم إرسال الواجب للطلاب', 'Homework sent to students'));
          },
          child: Text(context.tr('نشر', 'Publish')),
        ),
      ],
    );
  }
}
