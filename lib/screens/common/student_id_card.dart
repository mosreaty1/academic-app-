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
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
            colors: [Color(0xFF0D7561), AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CustomPaint(
          painter: BioPatternPainter(Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('أكاديمية د. راشيا', 'Dr. Rashia Academy'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(context.tr('بطاقة الطالب', 'STUDENT CARD'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: on ? AppColors.gold : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(on ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(on ? context.tr('مشترك', 'Premium') : context.tr('مجاني', 'Free'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  Avatar(student.name.initialOf(context), Colors.white.withValues(alpha: 0.22),
                      radius: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name.of(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${gradeName(context, student.grade)} • ${student.section}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78), fontSize: 12)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE6C36A), Color(0xFFB88A2A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('كود الطالب', 'STUDENT ID'),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  letterSpacing: 1.2)),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(student.code,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('نسخ', 'Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: student.code));
                        toast(context, context.tr('تم نسخ الكود', 'ID copied'));
                      },
                      icon: Icon(Icons.copy_rounded,
                          color: Colors.white.withValues(alpha: 0.85), size: 19),
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
