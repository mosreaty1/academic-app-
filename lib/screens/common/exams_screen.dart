import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import 'question_bank_screen.dart';

Color scoreColor(double p) => p >= 0.85
    ? AppColors.leaf
    : p >= 0.65
        ? AppColors.sky
        : p >= 0.5
            ? AppColors.amber
            : AppColors.coral;

String gradeLetter(BuildContext c, double p) => p >= 0.85
    ? c.tr('ممتاز', 'Excellent')
    : p >= 0.75
        ? c.tr('جيد جداً', 'Very good')
        : p >= 0.65
            ? c.tr('جيد', 'Good')
            : p >= 0.5
                ? c.tr('مقبول', 'Pass')
                : c.tr('ضعيف', 'Needs work');

class ExamsScreen extends StatelessWidget {
  final String studentId;
  const ExamsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isStudent = s.me!.role == UserRole.student;
    final st = s.user(studentId);
    final today = dayOnly(DateTime.now());
    final exams = s.examsOfGrade(st.grade);
    final open = <Exam>[];
    final upcoming = <Exam>[];
    final done = <Exam>[];
    final missed = <Exam>[];
    for (final e in exams) {
      final a = s.attemptOf(e.id, studentId);
      if (a != null) {
        done.add(e);
      } else if (dayOnly(e.date).isAfter(today)) {
        upcoming.add(e);
      } else if (dayOnly(e.date) == today) {
        open.add(e);
      } else {
        missed.add(e);
      }
    }
    final avg = s.averageScore(studentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent
            ? context.tr('الامتحانات', 'Exams')
            : context.tr('امتحانات ${st.name.ar}', '${st.name.en} • Exams')),
        actions: [
          if (isStudent)
            TextButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QuestionBankScreen())),
              icon: const Icon(Icons.quiz_outlined, size: 18),
              label: Text(context.tr('بنك الأسئلة', 'Question bank')),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          AppCard(
            gradient: const LinearGradient(
                colors: [Color(0xFF1B3A32), Color(0xFF0E241F)]),
            border: false,
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.gold, size: 38),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('متوسط درجاتك', 'Your average'),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85))),
                      Text(
                          avg == null ? '--' : '${(avg * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${done.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                    Text(context.tr('تم إنجازها', 'completed'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (open.isNotEmpty) ...[
            SectionHeader(context.tr('متاح الآن', 'Available now')),
            for (final e in open)
              _ExamCard(exam: e, studentId: studentId, canStart: isStudent),
          ],
          if (upcoming.isNotEmpty) ...[
            SectionHeader(context.tr('القادمة', 'Upcoming')),
            for (final e in upcoming)
              _ExamCard(exam: e, studentId: studentId, canStart: false),
          ],
          if (done.isNotEmpty) ...[
            SectionHeader(context.tr('النتائج', 'Results')),
            for (final e in done.reversed)
              _ExamCard(exam: e, studentId: studentId, canStart: false),
          ],
          if (missed.isNotEmpty) ...[
            SectionHeader(context.tr('فائتة', 'Missed')),
            for (final e in missed)
              _ExamCard(exam: e, studentId: studentId, canStart: false),
          ],
          if (exams.isEmpty)
            EmptyState(Icons.event_available_rounded,
                context.tr('لا توجد امتحانات بعد', 'No exams yet')),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String studentId;
  final bool canStart;
  const _ExamCard(
      {required this.exam, required this.studentId, required this.canStart});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final a = s.attemptOf(exam.id, studentId);
    final total = s.examTotal(exam);
    final today = dayOnly(DateTime.now());
    final isOpen = a == null && dayOnly(exam.date) == today;
    final upcoming = a == null && dayOnly(exam.date).isAfter(today);

    Widget trailing;
    if (a != null) {
      trailing = a.graded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${a.score}/${a.total}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: scoreColor(a.percent))),
                Text(gradeLetter(context, a.percent),
                    style: TextStyle(color: context.muted, fontSize: 12)),
              ],
            )
          : Pill(context.tr('بانتظار التصحيح', 'Awaiting grading'),
              AppColors.amber,
              icon: Icons.hourglass_top_rounded);
    } else if (isOpen) {
      trailing = Pill(context.tr('متاح', 'Open'), AppColors.leaf,
          icon: Icons.play_arrow_rounded);
    } else if (upcoming) {
      trailing = Pill(relativeDay(context, exam.date), AppColors.sky);
    } else {
      trailing = Pill(context.tr('فائت', 'Missed'), AppColors.coral);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () {
          if (a != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ExamResultScreen(examId: exam.id, studentId: studentId)));
          } else if (isOpen && canStart) {
            _showStart(context);
          } else if (upcoming) {
            toast(context,
                context.tr('يفتح الامتحان في ${fmtDateFull(context, exam.date)}',
                    'Opens on ${fmtDateFull(context, exam.date)}'));
          }
        },
        child: Row(
          children: [
            IconBadge(
                exam.kind == ExamKind.quiz
                    ? Icons.bolt_rounded
                    : Icons.assignment_rounded,
                AppColors.violet),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.title.of(context),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                      '${examKindLabel(context, exam.kind)} • ${fmtDate(context, exam.date)} • ${exam.durationMin} ${context.tr('د', 'min')} • $total ${context.tr('درجة', 'marks')}',
                      style: TextStyle(color: context.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showStart(BuildContext context) {
    final s = context.read<AppState>();
    final qs = exam.questionIds.map(s.question).toList();
    final mcq = qs.where((q) => q.type == QType.mcq).length;
    showSheet(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exam.title.of(ctx),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _Rule(Icons.timer_outlined,
              ctx.tr('المدة ${exam.durationMin} دقيقة', 'Duration ${exam.durationMin} minutes')),
          _Rule(Icons.checklist_rounded,
              ctx.tr('$mcq اختيار من متعدد و${qs.length - mcq} مقالي', '$mcq MCQ and ${qs.length - mcq} written')),
          _Rule(Icons.save_outlined,
              ctx.tr('يُسلَّم الامتحان تلقائياً عند انتهاء الوقت', 'Auto-submits when time is up')),
          _Rule(Icons.edit_note_rounded,
              ctx.tr('تصحح د. راشيا الأسئلة المقالية يدوياً', 'Dr. Rashia grades written answers manually')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ExamTakeScreen(exam: exam, studentId: studentId)));
            },
            child: Text(ctx.tr('ابدأ الامتحان', 'Start exam')),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Rule(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: context.brand),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Taking an exam
// ---------------------------------------------------------------------------

class ExamTakeScreen extends StatefulWidget {
  final Exam exam;
  final String studentId;
  const ExamTakeScreen({super.key, required this.exam, required this.studentId});

  @override
  State<ExamTakeScreen> createState() => _ExamTakeScreenState();
}

class _ExamTakeScreenState extends State<ExamTakeScreen> {
  late final List<Question> _qs;
  final Map<String, Object> _answers = {};
  final Map<String, TextEditingController> _ctrls = {};
  late int _remaining;
  Timer? _timer;
  int _index = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _qs = widget.exam.questionIds.map(s.question).toList();
    _remaining = widget.exam.durationMin * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _submit(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final sec = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  bool _isAnswered(Question q) {
    final a = _answers[q.id];
    if (a == null) return false;
    if (a is String) return a.trim().isNotEmpty;
    return true;
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitted) return;
    if (!auto) {
      final left = _qs.where((q) => !_isAnswered(q)).length;
      final ok = await confirm(
        context,
        context.tr('تسليم الامتحان؟', 'Submit exam?'),
        left == 0
            ? context.tr('لا يمكن التعديل بعد التسليم.', 'You cannot edit after submitting.')
            : context.tr('لديك $left سؤال بدون إجابة. هل تريد التسليم؟', 'You have $left unanswered question(s). Submit anyway?'),
        ok: context.tr('تسليم', 'Submit'),
      );
      if (!ok || !mounted) return;
    }
    _submitted = true;
    _timer?.cancel();
    final s = context.read<AppState>();
    s.submitExam(widget.exam, widget.studentId, Map.of(_answers));
    if (!mounted) return;
    if (auto) toast(context, context.tr('انتهى الوقت وتم التسليم تلقائياً', "Time's up - exam submitted"));
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ExamResultScreen(
                examId: widget.exam.id, studentId: widget.studentId)));
  }

  Future<void> _exit() async {
    final ok = await confirm(
      context,
      context.tr('الخروج من الامتحان؟', 'Leave the exam?'),
      context.tr('سيتم فقدان إجاباتك ولن تتمكن من المحاولة مجدداً.', 'Your answers will be lost.'),
      ok: context.tr('خروج', 'Leave'),
    );
    if (ok && mounted) {
      _submitted = true;
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _qs[_index];
    final low = _remaining < 120;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: _exit, icon: const Icon(Icons.close_rounded)),
          title: Text(widget.exam.title.of(context),
              style: const TextStyle(fontSize: 18)),
          actions: [
            Container(
              margin: const EdgeInsetsDirectional.only(end: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (low ? AppColors.coral : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(Icons.timer_outlined,
                    size: 16, color: low ? AppColors.coral : context.brand),
                const SizedBox(width: 4),
                Text(_clock,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: low ? AppColors.coral : context.brand,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _qs.length,
              minHeight: 4,
              backgroundColor: context.line,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(
                          context.tr('سؤال ${_index + 1} من ${_qs.length}',
                              'Question ${_index + 1} of ${_qs.length}'),
                          context.brand),
                      Pill(
                          q.type == QType.mcq
                              ? context.tr('اختيار من متعدد', 'MCQ')
                              : context.tr('مقالي', 'Written'),
                          q.type == QType.mcq ? AppColors.sky : AppColors.amber),
                      Text('${q.marks} ${context.tr('درجة', 'marks')}',
                          style: TextStyle(
                              color: context.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(q.text.of(context),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, height: 1.5)),
                  const SizedBox(height: 20),
                  if (q.type == QType.mcq)
                    for (var i = 0; i < q.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionTile(
                          letter: String.fromCharCode(65 + i),
                          text: q.options[i].of(context),
                          selected: _answers[q.id] == i,
                          onTap: () => setState(() => _answers[q.id] = i),
                        ),
                      )
                  else
                    TextField(
                      controller: _ctrls.putIfAbsent(
                          q.id, () => TextEditingController(text: (_answers[q.id] as String?) ?? '')),
                      maxLines: 9,
                      onChanged: (v) => _answers[q.id] = v,
                      decoration: InputDecoration(
                          hintText: context.tr('اكتب إجابتك هنا...', 'Write your answer here...')),
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
                  border: Border(top: BorderSide(color: context.line)),
                ),
                child: Row(
                  children: [
                    IconButton.outlined(
                      onPressed: _index == 0 ? null : () => setState(() => _index--),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _showMap,
                      icon: const Icon(Icons.grid_view_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _index == _qs.length - 1
                          ? FilledButton(
                              onPressed: () => _submit(),
                              child: Text(context.tr('تسليم', 'Submit')))
                          : FilledButton(
                              onPressed: () => setState(() => _index++),
                              child: Text(context.tr('التالي', 'Next'))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMap() {
    showSheet(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ctx.tr('خريطة الأسئلة', 'Question map'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _qs.length; i++)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _index = i);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isAnswered(_qs[i])
                          ? ctx.cs.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: i == _index ? AppColors.amber : ctx.line,
                          width: i == _index ? 2.4 : 1),
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _isAnswered(_qs[i]) ? Colors.white : ctx.ink)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.letter,
      required this.text,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? context.brandSoft : context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected ? context.cs.primary : context.line,
            width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? context.cs.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected ? context.cs.primary : context.line),
                ),
                child: Text(letter,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : context.muted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result + review
// ---------------------------------------------------------------------------

class ExamResultScreen extends StatelessWidget {
  final String examId;
  final String studentId;
  const ExamResultScreen(
      {super.key, required this.examId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final exam = s.exam(examId);
    final a = s.attemptOf(examId, studentId)!;
    final color = a.graded ? scoreColor(a.percent) : AppColors.amber;
    final target =
        a.graded ? a.percent : a.mcqScore / (a.total == 0 ? 1 : a.total);
    final isStudent = s.me!.role == UserRole.student;
    final p = a.percent;

    // Warm, proportional feedback (celebrate wins, encourage after misses).
    final (IconData badge, String headline, String body) = !a.graded
        ? (
            Icons.hourglass_top_rounded,
            context.tr('تم التسليم!', 'Submitted!'),
            context.tr('ستصحح د. راشيا الأسئلة المقالية قريباً وسيصلك إشعار بالنتيجة.',
                'Dr. Rashia will grade your written answers soon. We will notify you.')
          )
        : p >= 0.85
            ? (
                Icons.emoji_events_rounded,
                context.tr('أداء رائع!', 'Outstanding!'),
                context.tr('أتقنت هذا الدرس. استمر على هذا المستوى.',
                    'You have mastered this one. Keep it up.')
              )
            : p >= 0.65
                ? (
                    Icons.thumb_up_alt_rounded,
                    context.tr('عمل جيد!', 'Great job!'),
                    context.tr('أنت قريب جداً من الدرجة الكاملة. راجع الأخطاء وحاول التدريب.',
                        'You are close. Review the mistakes and practise a little more.')
                  )
                : p >= 0.5
                    ? (
                        Icons.trending_up_rounded,
                        context.tr('بداية جيدة', 'Good start'),
                        context.tr('بقليل من التدريب ستتحسن بسرعة. ابدأ بالأسئلة التي أخطأت فيها.',
                            'A little practice will lift this fast. Start with the questions you missed.')
                      )
                    : (
                        Icons.psychology_alt_rounded,
                        context.tr('لا تقلق', 'Do not worry'),
                        context.tr('كل خطأ فرصة للتعلم. راجع الشرح ثم جرّب بنك الأسئلة.',
                            'Every mistake is a chance to learn. Read the explanations, then try the question bank.')
                      );

    return Scaffold(
      appBar: AppBar(title: Text(exam.title.of(context))),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: target),
                      duration: const Duration(milliseconds: 1300),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => ProgressRing(
                        value: v,
                        color: color,
                        size: 144,
                        stroke: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                '${(v * (a.total == 0 ? 1 : a.total)).round()}${a.graded ? '' : '+'}',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [FontFeature.tabularFigures()])),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text('/ ${a.total}',
                                  style: TextStyle(color: context.muted, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge, color: color, size: 24),
                        const SizedBox(width: 8),
                        Text(headline,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(body,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.muted, height: 1.5)),
                    if (a.graded) ...[
                      const SizedBox(height: 12),
                      Pill('${(a.percent * 100).round()}%  •  ${gradeLetter(context, a.percent)}', color),
                    ],
                  ],
                ),
              ),
              if (isStudent) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuestionBankScreen())),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: Text(context.tr('تدرّب على أسئلة مشابهة', 'Practise similar questions')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('العودة للامتحانات', 'Back to exams')),
                ),
              ],
              SectionHeader(context.tr('مراجعة الإجابات', 'Answer review')),
              for (var i = 0; i < exam.questionIds.length; i++)
                _ReviewCard(
                    index: i + 1,
                    q: s.question(exam.questionIds[i]),
                    answer: a.answers[exam.questionIds[i]]),
            ],
          ),
          if (a.graded && p >= 0.85) const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final Question q;
  final Object? answer;
  const _ReviewCard({required this.index, required this.q, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isMcq = q.type == QType.mcq;
    final correct = isMcq && answer == q.answer;
    final color = isMcq
        ? (answer == null
            ? AppColors.amber
            : correct
                ? AppColors.leaf
                : AppColors.coral)
        : AppColors.sky;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Avatar('$index', color, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Text(q.text.of(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, height: 1.4)),
              ),
            ]),
            const SizedBox(height: 12),
            if (isMcq) ...[
              _line(context, context.tr('إجابتك', 'Your answer'),
                  answer == null ? context.tr('لم تجب', 'Not answered') : q.options[answer as int].of(context), color),
              if (!correct)
                _line(context, context.tr('الإجابة الصحيحة', 'Correct answer'),
                    q.options[q.answer].of(context), AppColors.leaf),
              if (q.explanation.ar.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: context.brandSoft,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 18, color: context.brand),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(q.explanation.of(context),
                            style: const TextStyle(fontSize: 12, height: 1.5))),
                  ]),
                ),
              ],
            ] else ...[
              _line(
                  context,
                  context.tr('إجابتك', 'Your answer'),
                  (answer is String && (answer as String).trim().isNotEmpty)
                      ? answer as String
                      : context.tr('لم تجب', 'Not answered'),
                  AppColors.sky),
              _line(context, context.tr('الإجابة النموذجية', 'Model answer'),
                  q.modelAnswer.of(context), AppColors.leaf),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 4,
              height: 36,
              margin: const EdgeInsetsDirectional.only(end: 12),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.muted, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
