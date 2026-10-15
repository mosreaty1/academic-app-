import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../common/exams_screen.dart';
import '../common/question_bank_screen.dart';

/// Teacher area: exams on one tab, the question bank on the other.
class TeacherExamsScreen extends StatelessWidget {
  const TeacherExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('الامتحانات والأسئلة', 'Exams & questions')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('الامتحانات', 'Exams')),
              Tab(text: context.tr('بنك الأسئلة', 'Question bank')),
            ],
          ),
        ),
        floatingActionButton: Builder(builder: (ctx) {
          final tc = DefaultTabController.of(ctx);
          return AnimatedBuilder(
            animation: tc,
            builder: (_, __) => tc.index == 0
                ? FloatingActionButton.extended(
                    onPressed: () => go(context, const CreateExamScreen()),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.tr('امتحان جديد', 'New exam')),
                  )
                : const AddQuestionFab(),
          );
        }),
        body: const TabBarView(
          children: [_ExamList(), QuestionBankBody()],
        ),
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final exams = [...s.exams]..sort((a, b) => b.date.compareTo(a.date));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
      children: [
        for (final e in exams)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Builder(builder: (_) {
              final atts = s.attemptsOfExam(e.id);
              final ungraded = atts.where((a) => !a.graded).length;
              final roster = s.studentsOfGrade(e.grade).length;
              return AppCard(
                onTap: () => go(context, ExamDetailScreen(examId: e.id)),
                child: Row(children: [
                  IconBadge(Icons.assignment_rounded, AppColors.violet),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title.of(context),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                            '${gradeShort(context, e.grade)} • ${fmtDate(context, e.date)} • ${e.questionIds.length} ${context.tr('سؤال', 'Q')} • ${s.examTotal(e)} ${context.tr('درجة', 'marks')}',
                            style: TextStyle(color: context.muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                            context.tr('سلّم ${atts.length} من $roster', '${atts.length} of $roster submitted'),
                            style: TextStyle(color: context.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (ungraded > 0)
                    Pill(context.tr('$ungraded للتصحيح', '$ungraded to grade'), AppColors.amber)
                  else
                    Icon(Icons.chevron_right_rounded, color: context.muted),
                ]),
              );
            }),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- detail ----

class ExamDetailScreen extends StatelessWidget {
  final String examId;
  const ExamDetailScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = s.exam(examId);
    final atts = s.attemptsOfExam(examId);
    final graded = atts.where((a) => a.graded).toList();
    final avg = graded.isEmpty
        ? null
        : graded.fold<double>(0, (x, a) => x + a.percent) / graded.length;
    final roster = s.studentsOfGrade(e.grade);

    return Scaffold(
      appBar: AppBar(title: Text(e.title.of(context))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Row(children: [
            Expanded(
              child: StatCard(
                icon: Icons.groups_rounded,
                color: AppColors.sky,
                value: '${atts.length}/${roster.length}',
                label: context.tr('سلّموا', 'Submitted'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.bar_chart_rounded,
                color: AppColors.leaf,
                value: avg == null ? '--' : '${(avg * 100).round()}%',
                label: context.tr('المتوسط', 'Average'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.pending_actions_rounded,
                color: AppColors.amber,
                value: '${atts.length - graded.length}',
                label: context.tr('للتصحيح', 'To grade'),
              ),
            ),
          ]),
          SectionHeader(context.tr('الطلاب', 'Students')),
          for (final st in roster)
            Builder(builder: (_) {
              final a = s.attemptOf(examId, st.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: a == null ? null : () => showSheet(context, (_) => GradeAttemptSheet(attempt: a)),
                  child: Row(children: [
                    Avatar(st.name.initialOf(context), st.color, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(st.name.of(context),
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (a == null)
                      Pill(context.tr('لم يسلّم', 'Not submitted'), AppColors.coral)
                    else if (!a.graded)
                      Pill(context.tr('صحّح الآن', 'Grade now'), AppColors.amber,
                          icon: Icons.edit_rounded)
                    else
                      Text('${a.score}/${a.total}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: scoreColor(a.percent))),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class GradeAttemptSheet extends StatefulWidget {
  final ExamAttempt attempt;
  const GradeAttemptSheet({super.key, required this.attempt});

  @override
  State<GradeAttemptSheet> createState() => _GradeAttemptSheetState();
}

class _GradeAttemptSheetState extends State<GradeAttemptSheet> {
  final Map<String, TextEditingController> _marks = {};

  @override
  void dispose() {
    for (final c in _marks.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final a = widget.attempt;
    final e = s.exam(a.examId);
    final st = s.user(a.studentId);
    final written = e.questionIds.map(s.question).where((q) => q.type == QType.written).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(st.name.of(context),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(e.title.of(context), style: TextStyle(color: context.muted)),
        const SizedBox(height: 16),
        Row(children: [
          Pill('MCQ: ${a.mcqScore}', AppColors.sky),
          const SizedBox(width: 8),
          if (a.graded)
            Pill(context.tr('الكلي ${a.score}/${a.total}', 'Total ${a.score}/${a.total}'), AppColors.leaf),
        ]),
        const SizedBox(height: 12),
        if (written.isEmpty)
          Text(context.tr('لا توجد أسئلة مقالية في هذا الامتحان.', 'No written questions in this exam.')),
        for (final q in written) ...[
          const Divider(height: 24),
          Text(q.text.of(context), style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: context.brandSoft, borderRadius: BorderRadius.circular(14)),
            child: Text(
                (a.answers[q.id] as String?)?.trim().isNotEmpty == true
                    ? a.answers[q.id] as String
                    : context.tr('لم يجب الطالب', 'No answer'),
                style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 8),
          Text(
              '${context.tr('النموذجية', 'Model')}: ${q.modelAnswer.of(context)}',
              style: TextStyle(color: context.muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 8),
          Row(children: [
            Text(context.tr('الدرجة (من ${q.marks})', 'Mark (out of ${q.marks})'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _marks.putIfAbsent(q.id, () => TextEditingController()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ]),
        ],
        if (written.isNotEmpty) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              var sum = 0;
              for (final q in written) {
                final v = int.tryParse(_marks[q.id]?.text ?? '') ?? 0;
                sum += v.clamp(0, q.marks);
              }
              s.gradeWritten(a, sum);
              Navigator.pop(context);
              toast(context, context.tr('تم حفظ الدرجة', 'Grade saved'));
            },
            child: Text(a.graded
                ? context.tr('تحديث الدرجة', 'Update grade')
                : context.tr('حفظ ونشر الدرجة', 'Save & publish grade')),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------- create ----

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '30');
  int _grade = 2;
  ExamKind _kind = ExamKind.quiz;
  DateTime _date = dayOnly(DateTime.now()).add(const Duration(days: 3));
  final Set<String> _picked = {};

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final qs = s.questions.where((q) => q.grade == _grade).toList();
    final total = _picked.fold<int>(0, (a, id) => a + s.question(id).marks);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('إنشاء امتحان', 'Create exam'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          LabeledField(context.tr('عنوان الامتحان', 'Exam title'), _title),
          ChipSelector<int>(
            values: const [1, 2, 3],
            selected: _grade,
            label: (g) => gradeName(context, g),
            onChanged: (g) => setState(() {
              _grade = g;
              _picked.clear();
            }),
          ),
          const SizedBox(height: 12),
          ChipSelector<ExamKind>(
            values: ExamKind.values,
            selected: _kind,
            label: (k) => examKindLabel(context, k),
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: dayOnly(DateTime.now()),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _date = d);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(fmtDateYear(context, _date)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    suffixText: context.tr('د', 'min'),
                    prefixIcon: const Icon(Icons.timer_outlined)),
              ),
            ),
          ]),
          SectionHeader(context.tr('اختر الأسئلة من البنك', 'Pick questions from the bank')),
          if (qs.isEmpty)
            EmptyState(Icons.help_outline_rounded, context.tr('لا توجد أسئلة لهذا الصف', 'No questions for this grade')),
          for (final q in qs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onTap: () => setState(() {
                  if (!_picked.remove(q.id)) _picked.add(q.id);
                }),
                child: Row(children: [
                  Checkbox(
                    value: _picked.contains(q.id),
                    onChanged: (_) => setState(() {
                      if (!_picked.remove(q.id)) _picked.add(q.id);
                    }),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.text.of(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                            '${q.type == QType.mcq ? 'MCQ' : context.tr('مقالي', 'Written')} • ${difficultyLabel(context, q.difficulty)} • ${q.marks} ${context.tr('درجة', 'marks')}',
                            style: TextStyle(color: context.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final t = _title.text.trim();
              if (t.isEmpty || _picked.isEmpty) {
                toast(context, context.tr('اكتب العنوان واختر سؤالاً واحداً على الأقل', 'Enter a title and pick at least one question'));
                return;
              }
              s.addExam(Exam(
                id: 'e${DateTime.now().microsecondsSinceEpoch}',
                title: Bi(t, t),
                grade: _grade,
                kind: _kind,
                date: _date,
                durationMin: int.tryParse(_duration.text) ?? 30,
                questionIds: _picked.toList(),
              ));
              Navigator.pop(context);
              toast(context, context.tr('تم نشر الامتحان للطلاب', 'Exam published to students'));
            },
            child: Text(context.tr('نشر الامتحان (${_picked.length} سؤال • $total درجة)',
                'Publish exam (${_picked.length} Q • $total marks)')),
          ),
        ],
      ),
    );
  }
}
