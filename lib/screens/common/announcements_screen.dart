import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final teacher = s.me!.role == UserRole.teacher;
    int grade = 0;
    if (s.me!.role == UserRole.student) grade = s.me!.grade;
    if (s.me!.role == UserRole.parent) grade = s.activeStudent.grade;
    final list = s.announcementsFor(grade);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('الإعلانات', 'Announcements'))),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: () => showSheet(context, (_) => const _PostForm()),
              icon: const Icon(Icons.campaign_rounded),
              label: Text(context.tr('إعلان جديد', 'New announcement')),
            )
          : null,
      body: list.isEmpty
          ? EmptyState(Icons.campaign_outlined, context.tr('لا توجد إعلانات', 'No announcements'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              children: [
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            if (a.pinned) ...[
                              const Icon(Icons.push_pin_rounded,
                                  size: 16, color: AppColors.amber),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(a.title.of(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15.5)),
                            ),
                            Pill(gradeShort(context, a.grade), AppColors.primary),
                          ]),
                          const SizedBox(height: 8),
                          Text(a.body.of(context), style: const TextStyle(height: 1.55)),
                          const SizedBox(height: 8),
                          Text(fmtDateFull(context, a.date),
                              style: TextStyle(color: context.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PostForm extends StatefulWidget {
  const _PostForm();

  @override
  State<_PostForm> createState() => _PostFormState();
}

class _PostFormState extends State<_PostForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _grade = 0;
  bool _pin = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('إعلان جديد', 'New announcement'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        LabeledField(context.tr('العنوان', 'Title'), _title),
        LabeledField(context.tr('النص', 'Message'), _body, maxLines: 4),
        ChipSelector<int>(
          values: const [0, 1, 2, 3],
          selected: _grade,
          label: (g) => g == 0 ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _pin,
          onChanged: (v) => setState(() => _pin = v),
          title: Text(context.tr('تثبيت في الأعلى', 'Pin to top')),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
              toast(context, context.tr('أكمل العنوان والنص', 'Fill title and message'));
              return;
            }
            final t = _title.text.trim();
            final b = _body.text.trim();
            context.read<AppState>().postAnnouncement(Announcement(
                  id: 'a${DateTime.now().microsecondsSinceEpoch}',
                  title: Bi(t, t),
                  body: Bi(b, b),
                  date: DateTime.now(),
                  grade: _grade,
                  pinned: _pin,
                ));
            Navigator.pop(context);
            toast(context, context.tr('تم نشر الإعلان', 'Announcement published'));
          },
          child: Text(context.tr('نشر', 'Publish')),
        ),
      ],
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('الإشعارات', 'Notifications')),
        actions: [
          TextButton(
            onPressed: s.markAllRead,
            child: Text(context.tr('تمييز الكل كمقروء', 'Mark all read')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          for (final n in s.notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                color: n.read ? null : context.brandSoft,
                child: Row(children: [
                  IconBadge(n.icon, n.color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title.of(context),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(n.body.of(context),
                            style: TextStyle(color: context.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(timeAgo(context, n.at),
                      style: TextStyle(color: context.muted, fontSize: 11)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
