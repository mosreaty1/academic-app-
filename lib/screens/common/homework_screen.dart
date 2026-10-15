import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

enum _HwState { pending, overdue, submitted, graded }

_HwState _stateOf(AppState s, Homework h, String sid) {
  final sub = s.submissionOf(h.id, sid);
  if (sub != null) return sub.mark != null ? _HwState.graded : _HwState.submitted;
  return dayOnly(h.due).isBefore(dayOnly(DateTime.now()))
      ? _HwState.overdue
      : _HwState.pending;
}

Color _stateColor(_HwState st) => switch (st) {
      _HwState.pending => AppColors.amber,
      _HwState.overdue => AppColors.coral,
      _HwState.submitted => AppColors.sky,
      _HwState.graded => AppColors.leaf,
    };

String _stateLabel(BuildContext c, _HwState st) => switch (st) {
      _HwState.pending => c.tr('مطلوب', 'To do'),
      _HwState.overdue => c.tr('متأخر', 'Overdue'),
      _HwState.submitted => c.tr('تم التسليم', 'Submitted'),
      _HwState.graded => c.tr('تم التصحيح', 'Graded'),
    };

class HomeworkScreen extends StatefulWidget {
  final String studentId;
  const HomeworkScreen({super.key, required this.studentId});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  int _tab = 0; // 0 = to do, 1 = done

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isStudent = s.me!.role == UserRole.student;
    final st = s.user(widget.studentId);
    final all = s.homeworksOfGrade(st.grade);
    final todo = all.where((h) {
      final x = _stateOf(s, h, widget.studentId);
      return x == _HwState.pending || x == _HwState.overdue;
    }).toList();
    final done = all.where((h) {
      final x = _stateOf(s, h, widget.studentId);
      return x == _HwState.submitted || x == _HwState.graded;
    }).toList();
    final list = _tab == 0 ? todo : done;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent
            ? context.tr('الواجبات', 'Homework')
            : context.tr('واجبات ${st.name.ar}', '${st.name.en} • Homework')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.line)),
            child: Row(children: [
              _seg(context, 0, context.tr('المطلوبة (${todo.length})', 'To do (${todo.length})')),
              _seg(context, 1, context.tr('المسلّمة (${done.length})', 'Done (${done.length})')),
            ]),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            EmptyState(
                _tab == 0 ? Icons.celebration_rounded : Icons.inbox_rounded,
                _tab == 0
                    ? context.tr('لا توجد واجبات مطلوبة!', 'No homework due!')
                    : context.tr('لم يتم تسليم أي واجب بعد', 'Nothing submitted yet')),
          for (final h in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HwCard(hw: h, studentId: widget.studentId),
            ),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, int i, String label) {
    final sel = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
              color: sel ? context.cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: sel ? Colors.white : context.muted)),
          ),
        ),
      ),
    );
  }
}

class _HwCard extends StatelessWidget {
  final Homework hw;
  final String studentId;
  const _HwCard({required this.hw, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final state = _stateOf(s, hw, studentId);
    final sub = s.submissionOf(hw.id, studentId);
    final color = _stateColor(state);
    return AppCard(
      onTap: () => showSheet(
          context, (_) => HomeworkSheet(hw: hw, studentId: studentId)),
      child: Row(
        children: [
          IconBadge(Icons.assignment_rounded, color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hw.title.of(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text(hw.chapter.of(context),
                    style: TextStyle(color: context.muted, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.event_rounded, size: 14, color: context.muted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                        '${fmtDate(context, hw.due)} • ${relativeDay(context, hw.due)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.muted, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pill(_stateLabel(context, state), color),
              if (sub?.mark != null) ...[
                const SizedBox(height: 6),
                Text('${sub!.mark}/${hw.maxMarks}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: color)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class HomeworkSheet extends StatefulWidget {
  final Homework hw;
  final String studentId;
  const HomeworkSheet({super.key, required this.hw, required this.studentId});

  @override
  State<HomeworkSheet> createState() => _HomeworkSheetState();
}

class _HomeworkSheetState extends State<HomeworkSheet> {
  final _text = TextEditingController();
  bool _attached = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hw = widget.hw;
    final sub = s.submissionOf(hw.id, widget.studentId);
    final isStudent = s.me!.role == UserRole.student;
    final overdue = dayOnly(hw.due).isBefore(dayOnly(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hw.title.of(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          Pill(hw.chapter.of(context), AppColors.primary),
          Pill('${context.tr('الموعد', 'Due')} ${fmtDate(context, hw.due)}', AppColors.amber),
          Pill('${hw.maxMarks} ${context.tr('درجة', 'marks')}', AppColors.violet),
        ]),
        const SizedBox(height: 14),
        Text(hw.description.of(context), style: const TextStyle(height: 1.6)),
        const SizedBox(height: 18),
        if (sub != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: context.brandSoft,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    context.tr('تم التسليم ${timeAgo(context, sub.at)}',
                        'Submitted ${timeAgo(context, sub.at)}'),
                    style: TextStyle(
                        color: context.brand, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(sub.text),
                if (sub.mark != null) ...[
                  const Divider(height: 22),
                  Text(
                      context.tr('الدرجة: ${sub.mark}/${hw.maxMarks}',
                          'Mark: ${sub.mark}/${hw.maxMarks}'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  if (sub.feedback.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub.feedback),
                  ],
                ],
              ],
            ),
          ),
          if (isStudent && sub.mark == null) ...[
            const SizedBox(height: 12),
            _form(context, s, resubmit: true),
          ],
        ] else if (isStudent)
          _form(context, s)
        else
          Text(
              overdue
                  ? context.tr('لم يتم تسليم الواجب بعد وقد انتهى الموعد.', 'Not submitted and the deadline has passed.')
                  : context.tr('لم يتم تسليم الواجب بعد.', 'Not submitted yet.'),
              style: const TextStyle(
                  color: AppColors.coral, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _form(BuildContext context, AppState s, {bool resubmit = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _text,
          maxLines: 4,
          decoration: InputDecoration(
              hintText: context.tr('اكتب إجابتك أو ملاحظاتك...', 'Type your answer or notes...')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => _attached = !_attached),
          icon: Icon(_attached ? Icons.check_circle_rounded : Icons.attach_file_rounded),
          label: Text(_attached
              ? context.tr('تم إرفاق صورة الحل', 'Solution photo attached')
              : context.tr('إرفاق صورة / ملف', 'Attach photo / file')),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            final t = _text.text.trim();
            if (t.isEmpty && !_attached) {
              toast(context, context.tr('اكتب إجابة أو أرفق ملفاً', 'Write an answer or attach a file'));
              return;
            }
            final body = [
              if (t.isNotEmpty) t,
              if (_attached) context.tr('صورة مرفقة','Photo attached'),
            ].join('\n');
            s.submitHomework(widget.hw.id, widget.studentId, body);
            Navigator.pop(context);
            toast(context, context.tr('تم تسليم الواجب','Homework submitted'));
          },
          child: Text(resubmit
              ? context.tr('إعادة التسليم', 'Resubmit')
              : context.tr('تسليم الواجب', 'Submit homework')),
        ),
      ],
    );
  }
}
