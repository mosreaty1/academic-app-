import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

/// Student card showing the unique student ID used to sign in.
class StudentIdCard extends StatelessWidget {
  final UserProfile student;
  const StudentIdCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final on = s.hasAccess(student.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: BioPatternPainter(Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.biotech_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(context.tr('أكاديمية د. راشيا', 'Dr. Rashia Academy'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5)),
                  ),
                  const SizedBox(width: 8),
                  Pill(on ? context.tr('مشترك', 'Subscribed') : context.tr('غير مشترك', 'Free'),
                      on ? AppColors.amber : Colors.white),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Avatar(student.name.initialOf(context), Colors.white.withValues(alpha: 0.28),
                      radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name.of(context),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                        Text('${gradeName(context, student.grade)} • ${student.section}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('كود الطالب', 'STUDENT ID'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10.5,
                                letterSpacing: 1)),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(student.code,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: context.tr('نسخ', 'Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: student.code));
                        toast(context, context.tr('تم نسخ الكود', 'ID copied'));
                      },
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
