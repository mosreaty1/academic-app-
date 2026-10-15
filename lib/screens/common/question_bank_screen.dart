import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

class QuestionBankScreen extends StatelessWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = context.read<AppState>().me!.role == UserRole.teacher;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('بنك الأسئلة', 'Question bank'))),
      floatingActionButton: teacher ? const AddQuestionFab() : null,
      body: const QuestionBankBody(),
    );
  }
}

class AddQuestionFab extends StatelessWidget {
  const AddQuestionFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showSheet(context, (_) => const AddQuestionForm()),
      icon: const Icon(Icons.add_rounded),
      label: Text(context.tr('سؤال جديد', 'New question')),
    );
  }
}

class QuestionBankBody extends StatefulWidget {
  const QuestionBankBody({super.key});

  @override
  State<QuestionBankBody> createState() => _QuestionBankBodyState();
}

class _QuestionBankBodyState extends State<QuestionBankBody> {
  int? _grade; // null = own grade (student) / all (teacher)
  String? _chapter; // chapter.en
  QType? _type;
  Difficulty? _diff;
  bool _onlySaved = false;
  String _query = '';
  final _search = TextEditingController();
  final List<String> _recent = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String v) {
    _search.text = v;
    _search.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _query = v);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final grade = teacher ? _grade : s.me!.grade;

    var list = s.questions.where((q) {
      if (grade != null && q.grade != grade) return false;
      if (_chapter != null && q.chapter.en != _chapter) return false;
      if (_type != null && q.type != _type) return false;
      if (_diff != null && q.difficulty != _diff) return false;
      if (_onlySaved && !s.bookmarks.contains(q.id)) return false;
      if (_query.isNotEmpty &&
          !(q.text.ar.contains(_query) ||
              q.text.en.toLowerCase().contains(_query.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();

    final chapters = <Bi>[];
    final seen = <String>{};
    for (final q in s.questions.where((q) => grade == null || q.grade == grade)) {
      if (seen.add(q.chapter.en)) chapters.add(q.chapter);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
      children: [
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (v) {
            final q = v.trim();
            if (q.isNotEmpty) {
              setState(() {
                _recent.remove(q);
                _recent.insert(0, q);
                if (_recent.length > 4) _recent.removeLast();
              });
            }
          },
          decoration: InputDecoration(
            hintText: context.tr('ابحث في الأسئلة...', 'Search questions...'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _setQuery('')),
          ),
        ),
        if (_query.isEmpty)
          SearchSuggestions(
            recent: _recent,
            popular: [
              context.tr('الميتوكوندريا', 'mitochondria'),
              context.tr('القلب', 'heart'),
              context.tr('DNA', 'DNA'),
            ],
            onPick: _setQuery,
          ),
        const SizedBox(height: 12),
        if (teacher) ...[
          ChipSelector<int?>(
            values: const [null, 1, 2, 3],
            selected: _grade,
            label: (g) => g == null ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, g),
            onChanged: (g) => setState(() {
              _grade = g;
              _chapter = null;
            }),
          ),
          const SizedBox(height: 8),
        ],
        ChipSelector<String?>(
          values: [null, ...chapters.map((c) => c.en)],
          selected: _chapter,
          label: (en) => en == null
              ? context.tr('كل الفصول', 'All chapters')
              : chapters.firstWhere((c) => c.en == en).of(context),
          onChanged: (v) => setState(() => _chapter = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChipSelector<QType?>(
                values: const [null, QType.mcq, QType.written],
                selected: _type,
                label: (t) => t == null
                    ? context.tr('كل الأنواع', 'All types')
                    : t == QType.mcq
                        ? context.tr('اختيار من متعدد', 'MCQ')
                        : context.tr('مقالي', 'Written'),
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChipSelector<Difficulty?>(
                values: const [null, Difficulty.easy, Difficulty.medium, Difficulty.hard],
                selected: _diff,
                label: (d) => d == null
                    ? context.tr('كل المستويات', 'Any level')
                    : difficultyLabel(context, d),
                onChanged: (v) => setState(() => _diff = v),
              ),
            ),
            IconButton(
              tooltip: context.tr('المحفوظة', 'Saved'),
              onPressed: () => setState(() => _onlySaved = !_onlySaved),
              icon: Icon(
                  _onlySaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _onlySaved ? AppColors.amber : context.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            context.tr('${list.length} سؤال', '${list.length} questions'),
            style: TextStyle(color: context.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (list.isEmpty)
          EmptyState(Icons.search_off_rounded,
              context.tr('لا توجد أسئلة مطابقة', 'No matching questions'),
              subtitle: context.tr('جرّب كلمات أخرى أو أزل الفلاتر.', 'Try different words or clear the filters.'),
              actionLabel: context.tr('مسح الفلاتر', 'Clear filters'),
              onAction: () {
                _setQuery('');
                setState(() {
                  _chapter = null;
                  _type = null;
                  _diff = null;
                  _onlySaved = false;
                });
              }),
        for (final q in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuestionCard(key: ValueKey(q.id), q: q, teacher: teacher),
          ),
      ],
    );
  }
}

class QuestionCard extends StatefulWidget {
  final Question q;
  final bool teacher;
  const QuestionCard({super.key, required this.q, required this.teacher});

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _picked;
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = widget.q;
    final saved = s.bookmarks.contains(q.id);
    final showAnswer = widget.teacher || _reveal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Pill(gradeShort(context, q.grade), AppColors.primary),
            const SizedBox(width: 8),
            Pill(difficultyLabel(context, q.difficulty), difficultyColor(q.difficulty)),
            const SizedBox(width: 8),
            Pill(q.type == QType.mcq ? 'MCQ' : context.tr('مقالي', 'Written'), AppColors.sky),
            const Spacer(),
            if (!widget.teacher)
              InkWell(
                onTap: () => s.toggleBookmark(q.id),
                child: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: saved ? AppColors.amber : context.muted),
              ),
          ]),
          const SizedBox(height: 4),
          Text(q.chapter.of(context),
              style: TextStyle(color: context.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(q.text.of(context),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          if (q.type == QType.mcq)
            for (var i = 0; i < q.options.length; i++) _option(context, s, i)
          else if (showAnswer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.brandSoft,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('الإجابة النموذجية', 'Model answer'),
                      style: TextStyle(
                          color: context.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(q.modelAnswer.of(context), style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          if (q.type == QType.mcq && _reveal && !widget.teacher)
            _FeedbackBanner(correct: _picked == q.answer),
          if (q.type == QType.mcq && showAnswer && q.explanation.ar.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.brandSoft,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: context.brand),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(q.explanation.of(context),
                          style: const TextStyle(fontSize: 14, height: 1.5))),
                ],
              ),
            ),
          if (q.type == QType.written && !widget.teacher && !_reveal)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: () => setState(() => _reveal = true),
              child: Text(context.tr('أظهر الإجابة النموذجية', 'Show model answer')),
            ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, AppState s, int i) {
    final q = widget.q;
    final isAnswer = i == q.answer;
    final picked = _picked == i;
    Color? bg;
    Color border = context.line;
    IconData? icon;
    if (widget.teacher) {
      if (isAnswer) {
        bg = AppColors.leaf.withValues(alpha: 0.14);
        border = AppColors.leaf;
        icon = Icons.check_circle_rounded;
      }
    } else if (_reveal) {
      if (isAnswer) {
        bg = AppColors.leaf.withValues(alpha: 0.14);
        border = AppColors.leaf;
        icon = Icons.check_circle_rounded;
      } else if (picked) {
        bg = AppColors.coral.withValues(alpha: 0.14);
        border = AppColors.coral;
        icon = Icons.cancel_rounded;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.teacher || _reveal
            ? null
            : () {
                setState(() {
                  _picked = i;
                  _reveal = true;
                });
                s.recordPractice(s.me!.id, q.id, i == q.answer);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(children: [
            Text(String.fromCharCode(65 + i),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: context.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(q.options[i].of(context),
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            if (icon != null)
              Icon(icon, color: isAnswer ? AppColors.leaf : AppColors.coral, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// Encouraging reaction after a practice answer (not just a green/red mark).
class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  const _FeedbackBanner({required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.leaf : AppColors.amber;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(scale: v, alignment: Alignment.centerLeft, child: c),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(correct ? Icons.celebration_rounded : Icons.tips_and_updates_rounded,
              color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                correct
                    ? context.tr('إجابة صحيحة! أحسنت، واصل.', 'Correct! Nice work, keep going.')
                    : context.tr('قريب! اقرأ الشرح وستتذكرها المرة القادمة.',
                        'So close! Read the explanation and you will nail it next time.'),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, height: 1.4)),
          ),
        ]),
      ),
    );
  }
}

class AddQuestionForm extends StatefulWidget {
  const AddQuestionForm({super.key});

  @override
  State<AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<AddQuestionForm> {
  int _grade = 1;
  QType _type = QType.mcq;
  Difficulty _diff = Difficulty.medium;
  int _answer = 0;
  Bi? _chapter;
  final _text = TextEditingController();
  final _expl = TextEditingController();
  final _marks = TextEditingController(text: '1');
  final _opts = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    _text.dispose();
    _expl.dispose();
    _marks.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final chapters = s.chaptersOf(_grade);
    _chapter ??= chapters.isEmpty ? null : chapters.first;
    if (_chapter != null && !chapters.any((c) => c.en == _chapter!.en)) {
      _chapter = chapters.isEmpty ? null : chapters.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('إضافة سؤال لبنك الأسئلة', 'Add a bank question'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ChipSelector<int>(
          values: const [1, 2, 3],
          selected: _grade,
          label: (g) => gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 12),
        if (chapters.isNotEmpty)
          ChipSelector<String>(
            values: chapters.map((c) => c.en).toList(),
            selected: _chapter!.en,
            label: (en) => chapters.firstWhere((c) => c.en == en).of(context),
            onChanged: (en) =>
                setState(() => _chapter = chapters.firstWhere((c) => c.en == en)),
          ),
        const SizedBox(height: 12),
        ChipSelector<QType>(
          values: QType.values,
          selected: _type,
          label: (t) => t == QType.mcq
              ? context.tr('اختيار من متعدد', 'MCQ')
              : context.tr('مقالي', 'Written'),
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 12),
        ChipSelector<Difficulty>(
          values: Difficulty.values,
          selected: _diff,
          label: (d) => difficultyLabel(context, d),
          onChanged: (d) => setState(() => _diff = d),
        ),
        const SizedBox(height: 16),
        LabeledField(context.tr('نص السؤال', 'Question text'), _text, maxLines: 3),
        if (_type == QType.mcq) ...[
          RadioGroup<int>(
            groupValue: _answer,
            onChanged: (v) => setState(() => _answer = v ?? 0),
            child: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Radio<int>(value: i),
                      Expanded(
                        child: TextField(
                          controller: _opts[i],
                          decoration: InputDecoration(
                              hintText: context.tr('الاختيار ${String.fromCharCode(65 + i)}',
                                  'Option ${String.fromCharCode(65 + i)}')),
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          Text(context.tr('اختر الدائرة بجوار الإجابة الصحيحة',
              'Select the circle next to the correct answer'),
              style: TextStyle(color: context.muted, fontSize: 12)),
          const SizedBox(height: 12),
        ],
        LabeledField(
            _type == QType.mcq
                ? context.tr('شرح الإجابة (اختياري)', 'Explanation (optional)')
                : context.tr('الإجابة النموذجية', 'Model answer'),
            _expl,
            maxLines: 3),
        LabeledField(context.tr('الدرجة', 'Marks'), _marks,
            keyboard: TextInputType.number),
        FilledButton(onPressed: _save, child: Text(context.tr('حفظ السؤال', 'Save question'))),
      ],
    );
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty || _chapter == null) {
      toast(context, context.tr('اكتب نص السؤال', 'Enter the question text'));
      return;
    }
    if (_type == QType.mcq && _opts.any((c) => c.text.trim().isEmpty)) {
      toast(context, context.tr('أكمل الاختيارات الأربعة', 'Fill in all four options'));
      return;
    }
    final s = context.read<AppState>();
    final expl = _expl.text.trim();
    s.addQuestion(Question(
      id: 'q${DateTime.now().microsecondsSinceEpoch}',
      grade: _grade,
      chapter: _chapter!,
      type: _type,
      text: Bi(text, text),
      options: _type == QType.mcq
          ? _opts.map((c) => Bi(c.text.trim(), c.text.trim())).toList()
          : const [],
      answer: _answer,
      explanation: _type == QType.mcq ? Bi(expl, expl) : const Bi('', ''),
      modelAnswer: _type == QType.written ? Bi(expl, expl) : const Bi('', ''),
      difficulty: _diff,
      marks: int.tryParse(_marks.text) ?? 1,
    ));
    Navigator.pop(context);
    toast(context, context.tr('تمت إضافة السؤال', 'Question added'));
  }
}
