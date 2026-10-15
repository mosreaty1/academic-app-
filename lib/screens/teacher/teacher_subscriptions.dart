import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../common/subscription_screen.dart';

/// Dr. Rashia manages subscribers and prepaid activation codes.
class TeacherSubscriptionsScreen extends StatelessWidget {
  const TeacherSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('الاشتراكات', 'Subscriptions')),
          bottom: TabBar(tabs: [
            Tab(text: context.tr('المشتركون', 'Subscribers')),
            Tab(text: context.tr('أكواد التفعيل', 'Codes')),
          ]),
        ),
        body: const TabBarView(children: [_Subscribers(), _Codes()]),
      ),
    );
  }
}

class _Subscribers extends StatefulWidget {
  const _Subscribers();

  @override
  State<_Subscribers> createState() => _SubscribersState();
}

class _SubscribersState extends State<_Subscribers> {
  int? _grade;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.students.where((u) => _grade == null || u.grade == _grade).toList()
      ..sort((a, b) {
        final x = s.hasAccess(b.id) ? 1 : 0;
        final y = s.hasAccess(a.id) ? 1 : 0;
        return x.compareTo(y);
      });
    final active = s.students.where((u) => s.hasAccess(u.id)).length;
    final revenue = s.subscriptions
        .where((x) => x.source == SubSource.payment)
        .fold<double>(0, (a, x) => a + AppState.plan(x.planId).price);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(children: [
          Expanded(
              child: StatCard(
                  icon: Icons.verified_rounded,
                  color: AppColors.leaf,
                  value: '$active',
                  label: context.tr('مشترك فعّال', 'Active'))),
          const SizedBox(width: 10),
          Expanded(
              child: StatCard(
                  icon: Icons.person_off_rounded,
                  color: AppColors.coral,
                  value: '${s.students.length - active}',
                  label: context.tr('غير مشترك', 'Not subscribed'))),
          const SizedBox(width: 10),
          Expanded(
              child: StatCard(
                  icon: Icons.payments_rounded,
                  color: AppColors.amber,
                  value: money(context, revenue),
                  label: context.tr('إيراد الدفع', 'Online revenue'))),
        ]),
        const SizedBox(height: 14),
        ChipSelector<int?>(
          values: const [null, 1, 2, 3],
          selected: _grade,
          label: (g) => g == null ? context.tr('الكل', 'All') : gradeShort(context, g),
          onChanged: (g) => setState(() => _grade = g),
        ),
        const SizedBox(height: 12),
        for (final u in list)
          Builder(builder: (_) {
            final sub = s.subscriptionOf(u.id);
            final on = sub?.active ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => showSheet(context, (_) => _ActivateSheet(student: u)),
                child: Row(children: [
                  Avatar(u.name.initialOf(context), u.color, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name.of(context),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${u.code} • ${gradeShort(context, u.grade)}',
                            style: TextStyle(color: context.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Pill(
                        on
                            ? context.tr('${sub!.daysLeft} يوم', '${sub.daysLeft} days')
                            : sub == null
                                ? context.tr('لا اشتراك', 'None')
                                : context.tr('منتهي', 'Expired'),
                        on ? AppColors.leaf : AppColors.coral),
                  ]),
                ]),
              ),
            );
          }),
      ],
    );
  }
}

class _ActivateSheet extends StatelessWidget {
  final UserProfile student;
  const _ActivateSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(student.name.of(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        Text(student.code, style: TextStyle(color: context.muted)),
        const SizedBox(height: 14),
        Text(context.tr('تفعيل / تمديد يدوي', 'Activate / extend manually'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final p in AppState.plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                s.grantSubscription(student.id, p, SubSource.manual);
                Navigator.pop(context);
                toast(context, context.tr('تم التفعيل', 'Activated'));
              },
              child: Text('${p.name.of(context)} • ${p.months} ${context.tr('شهر', 'mo')}'),
            ),
          ),
      ],
    );
  }
}

class _Codes extends StatelessWidget {
  const _Codes();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        FilledButton.icon(
          onPressed: () => showSheet(context, (_) => const _GenerateSheet()),
          icon: const Icon(Icons.add_card_rounded),
          label: Text(context.tr('إنشاء أكواد جديدة', 'Generate new codes')),
        ),
        const SizedBox(height: 14),
        if (s.codes.isEmpty)
          EmptyState(Icons.confirmation_number_outlined,
              context.tr('لا توجد أكواد', 'No codes yet')),
        for (final c in s.codes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(c.code,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 1.2,
                                decoration: c.used ? TextDecoration.lineThrough : null,
                                color: c.used ? context.muted : context.ink)),
                      ),
                      Text(
                          '${AppState.plan(c.planId).name.of(context)} • ${c.grade == 0 ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, c.grade)}${c.used ? ' • ${s.users.where((u) => u.id == c.usedBy).map((u) => u.name.of(context)).join()}' : ''}',
                          style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (c.used)
                  Pill(context.tr('مستخدم', 'Used'), AppColors.muted)
                else
                  IconButton(
                    tooltip: context.tr('نسخ', 'Copy'),
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.code));
                      toast(context, context.tr('تم نسخ الكود', 'Code copied'));
                    },
                  ),
              ]),
            ),
          ),
      ],
    );
  }
}

class _GenerateSheet extends StatefulWidget {
  const _GenerateSheet();

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  String _plan = 'monthly';
  int _grade = 0;
  int _qty = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('إنشاء أكواد تفعيل', 'Generate activation codes'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ChipSelector<String>(
          values: AppState.plans.map((p) => p.id).toList(),
          selected: _plan,
          label: (id) => AppState.plan(id).name.of(context),
          onChanged: (v) => setState(() => _plan = v),
        ),
        const SizedBox(height: 10),
        ChipSelector<int>(
          values: const [0, 1, 2, 3],
          selected: _grade,
          label: (g) => g == 0 ? context.tr('كل الصفوف', 'All grades') : gradeShort(context, g),
          onChanged: (v) => setState(() => _grade = v),
        ),
        const SizedBox(height: 10),
        ChipSelector<int>(
          values: const [1, 5, 10, 25, 50],
          selected: _qty,
          label: (n) => '$n',
          onChanged: (v) => setState(() => _qty = v),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            final made = context.read<AppState>().generateCodes(_plan, _grade, _qty);
            Clipboard.setData(ClipboardData(text: made.map((c) => c.code).join('\n')));
            Navigator.pop(context);
            toast(context, context.tr('تم إنشاء ${made.length} كود ونسخها', '${made.length} codes created and copied'));
          },
          child: Text(context.tr('إنشاء ونسخ', 'Generate & copy')),
        ),
      ],
    );
  }
}

/// Shortcut used by parents: pick the child and open their subscription page.
Widget buildSubscriptionPage(String id) => SubscriptionScreen(studentId: id);
