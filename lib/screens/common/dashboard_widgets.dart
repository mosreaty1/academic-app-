import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import 'announcements_screen.dart';

String roomLabel(BuildContext c, String room) {
  if (!c.isAr) return room;
  return room.replaceFirst('Hall', 'قاعة').replaceFirst('Lab', 'معمل');
}

String greeting(BuildContext c) {
  final h = DateTime.now().hour;
  if (h < 12) return c.tr('صباح الخير', 'Good morning');
  if (h < 18) return c.tr('مساء الخير', 'Good afternoon');
  return c.tr('مساء النور', 'Good evening');
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.select<AppState, int>((s) => s.unreadCount);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => go(context, const NotificationsScreen()),
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16)),
        ),
        if (n > 0)
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.amber, shape: BoxShape.circle),
              child: Text('$n',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class QuickAction {
  final IconData icon;
  final Color color;
  final String ar;
  final String en;
  final VoidCallback onTap;
  const QuickAction(this.icon, this.color, this.ar, this.en, this.onTap);
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActionGrid(this.actions, {super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: [
        for (var i = 0; i < actions.length; i++)
          Reveal(
            index: i,
            child: Material(
              color: context.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: actions[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconBadge(actions[i].icon, actions[i].color, size: 42),
                      const SizedBox(height: 8),
                      Text(context.tr(actions[i].ar, actions[i].en),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, height: 1.25)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dr. Rashia's classes for the given grade (or all grades when [grade] is null)
/// happening today.
class TodayClassesCard extends StatelessWidget {
  final int? grade;
  const TodayClassesCard({super.key, this.grade});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final slots = s.slotsFor(now.weekday, grade: grade);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBadge(Icons.calendar_today_rounded, AppColors.sky, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('حصص اليوم', "Today's classes"),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(fmtDateFull(context, now),
                      style: TextStyle(color: context.muted, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(context.tr('لا توجد حصص اليوم', 'No classes today'),
                  style: TextStyle(color: context.muted)),
            ),
          for (final sl in slots)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.brandSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Column(children: [
                  Text(fmtClock(context, sl.time),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: context.brand)),
                  Text('${sl.minutes} ${context.tr('د', 'min')}',
                      style: TextStyle(color: context.muted, fontSize: 12)),
                ]),
                Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: context.line),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sl.topic.of(context),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          grade == null
                              ? '${gradeName(context, sl.grade)} • ${roomLabel(context, sl.room)}'
                              : '${context.tr('د. راشيا', 'Dr. Rashia')} • ${roomLabel(context, sl.room)}',
                          style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class AnnouncementPreview extends StatelessWidget {
  final int grade;
  const AnnouncementPreview({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.announcementsFor(grade);
    if (list.isEmpty) return const SizedBox.shrink();
    final a = list.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.tr('آخر الإعلانات', 'Latest announcement'),
            action: context.tr('الكل', 'See all'),
            onAction: () => go(context, const AnnouncementsScreen())),
        AppCard(
          onTap: () => go(context, const AnnouncementsScreen()),
          color: AppColors.amber.withValues(alpha: context.isDark ? 0.16 : 0.1),
          child: Row(children: [
            const Icon(Icons.campaign_rounded, color: AppColors.amber, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title.of(context),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(a.body.of(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.muted, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

/// Upcoming homework deadlines and exams for a student.
class UpcomingList extends StatelessWidget {
  final String studentId;
  final VoidCallback? onExams;
  final VoidCallback? onHomework;
  const UpcomingList(
      {super.key, required this.studentId, this.onExams, this.onHomework});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.user(studentId);
    final today = dayOnly(DateTime.now());
    final items = <({DateTime date, Widget tile})>[];

    for (final e in s.examsOfGrade(st.grade)) {
      if (s.attemptOf(e.id, studentId) != null) continue;
      if (dayOnly(e.date).isBefore(today)) continue;
      items.add((
        date: e.date,
        tile: _tile(context, Icons.quiz_rounded, AppColors.violet, e.title.of(context),
            '${examKindLabel(context, e.kind)} • ${relativeDay(context, e.date)}', onExams),
      ));
    }
    for (final h in s.homeworksOfGrade(st.grade)) {
      if (s.submissionOf(h.id, studentId) != null) continue;
      if (dayOnly(h.due).isBefore(today)) continue;
      items.add((
        date: h.due,
        tile: _tile(context, Icons.assignment_rounded, AppColors.amber, h.title.of(context),
            '${context.tr('واجب', 'Homework')} • ${relativeDay(context, h.due)}', onHomework),
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.tr('القادم', 'Coming up')),
        if (items.isEmpty)
          AppCard(
              child: Row(children: [
            const IconBadge(Icons.check_circle_rounded, AppColors.leaf),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('كل شيء تحت السيطرة! لا مهام قادمة.', "You're all caught up!")))
          ])),
        for (final i in items.take(4))
          Padding(padding: const EdgeInsets.only(bottom: 8), child: i.tile),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String title,
      String sub, VoidCallback? onTap) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        IconBadge(icon, color, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(color: context.muted, fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: context.muted),
      ]),
    );
  }
}
