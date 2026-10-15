import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

String _catLabel(BuildContext c, String cat) {
  switch (cat) {
    case 'absence':
      return c.tr('عذر غياب', 'Absence excuse');
    case 'academic':
      return c.tr('سؤال أكاديمي', 'Academic question');
    case 'technical':
      return c.tr('مشكلة تقنية', 'Technical issue');
    case 'store':
      return c.tr('المتجر والطلبات', 'Store & orders');
    default:
      return c.tr('أخرى', 'Other');
  }
}

IconData _catIcon(String cat) {
  switch (cat) {
    case 'absence':
      return Icons.medical_services_rounded;
    case 'academic':
      return Icons.help_center_rounded;
    case 'technical':
      return Icons.build_circle_rounded;
    case 'store':
      return Icons.local_shipping_rounded;
    default:
      return Icons.chat_bubble_rounded;
  }
}

const _cats = ['academic', 'absence', 'technical', 'store', 'other'];

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  TicketStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    final list = s.myTickets
        .where((t) => _filter == null || t.status == _filter)
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: Text(teacher
              ? context.tr('تذاكر الدعم', 'Support tickets')
              : context.tr('تذاكري', 'My tickets'))),
      floatingActionButton: teacher
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showSheet(context, (_) => const _NewTicketForm()),
              icon: const Icon(Icons.add_comment_rounded),
              label: Text(context.tr('تذكرة جديدة', 'New ticket')),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          ChipSelector<TicketStatus?>(
            values: [null, ...TicketStatus.values],
            selected: _filter,
            label: (t) => t == null ? context.tr('الكل', 'All') : ticketStatusLabel(context, t),
            onChanged: (t) => setState(() => _filter = t),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyState(Icons.support_agent_rounded,
                context.tr('لا توجد تذاكر', 'No tickets'),
                subtitle: context.tr('اضغط "تذكرة جديدة" للتواصل مع د. راشيا',
                    'Tap "New ticket" to contact Dr. Rashia')),
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t))),
                child: Row(children: [
                  IconBadge(_catIcon(t.category), ticketStatusColor(t.status)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.subject,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                            teacher
                                ? '${s.user(t.authorId).name.of(context)} • ${t.id}'
                                : '${_catLabel(context, t.category)} • ${t.id}',
                            style: TextStyle(color: context.muted, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(
                            t.messages.last.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Pill(ticketStatusLabel(context, t.status), ticketStatusColor(t.status)),
                      const SizedBox(height: 6),
                      Text(timeAgo(context, t.messages.last.at),
                          style: TextStyle(color: context.muted, fontSize: 11)),
                    ],
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewTicketForm extends StatefulWidget {
  const _NewTicketForm();

  @override
  State<_NewTicketForm> createState() => _NewTicketFormState();
}

class _NewTicketFormState extends State<_NewTicketForm> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String _cat = 'academic';

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('تذكرة جديدة', 'New support ticket'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ChipSelector<String>(
          values: _cats,
          selected: _cat,
          label: (c) => _catLabel(context, c),
          onChanged: (c) => setState(() => _cat = c),
        ),
        const SizedBox(height: 14),
        LabeledField(context.tr('الموضوع', 'Subject'), _subject),
        LabeledField(context.tr('التفاصيل', 'Details'), _body, maxLines: 4),
        FilledButton(
          onPressed: () {
            if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
              toast(context, context.tr('أكمل الموضوع والتفاصيل', 'Fill in subject and details'));
              return;
            }
            context
                .read<AppState>()
                .createTicket(_subject.text.trim(), _cat, _body.text.trim());
            Navigator.pop(context);
            toast(context, context.tr('تم إرسال التذكرة', 'Ticket sent'));
          },
          child: Text(context.tr('إرسال', 'Send')),
        ),
      ],
    );
  }
}

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = widget.ticket;
    final teacher = s.me!.role == UserRole.teacher;
    final resolved = t.status == TicketStatus.resolved;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.id),
        actions: [
          if (teacher && !resolved)
            TextButton.icon(
              onPressed: () => s.setTicketStatus(t, TicketStatus.resolved),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(context.tr('تم الحل', 'Resolve')),
            ),
          if (teacher && resolved)
            TextButton(
              onPressed: () => s.setTicketStatus(t, TicketStatus.open),
              child: Text(context.tr('إعادة فتح', 'Reopen')),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppCard(
              child: Row(children: [
                IconBadge(_catIcon(t.category), ticketStatusColor(t.status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.subject,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(_catLabel(context, t.category),
                          style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Pill(ticketStatusLabel(context, t.status), ticketStatusColor(t.status)),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in t.messages) _Bubble(msg: m, mine: m.staff == teacher),
              ],
            ),
          ),
          if (!resolved)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                          hintText: context.tr('اكتب رداً...', 'Write a reply...')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      s.replyTicket(t, v);
                      _ctrl.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.tr('تم حل هذه التذكرة', 'This ticket is resolved'),
                  style: TextStyle(color: context.muted)),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final TicketMsg msg;
  final bool mine;
  const _Bubble({required this.msg, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: mine ? context.cs.primary : context.card,
          border: mine ? null : Border.all(color: context.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.staff && !mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(context.tr('د. راشيا', 'Dr. Rashia'),
                    style: TextStyle(
                        color: context.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5)),
              ),
            Text(msg.text,
                style: TextStyle(
                    color: mine ? Colors.white : context.ink, height: 1.45)),
            const SizedBox(height: 4),
            Text(timeAgo(context, msg.at),
                style: TextStyle(
                    fontSize: 10.5,
                    color: mine ? Colors.white70 : context.muted)),
          ],
        ),
      ),
    );
  }
}
