import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

String subSourceLabel(BuildContext c, SubSource s) => switch (s) {
      SubSource.code => c.tr('كود تفعيل', 'Activation code'),
      SubSource.payment => c.tr('دفع إلكتروني', 'Online payment'),
      SubSource.manual => c.tr('تفعيل يدوي', 'Manual'),
    };

/// Plans, status and code redemption for one student (student or parent view).
class SubscriptionScreen extends StatefulWidget {
  final String studentId;
  const SubscriptionScreen({super.key, required this.studentId});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    final r = await s.redeemCode(widget.studentId, _code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == 'ok') {
      _code.clear();
      final end = s.subscriptionOf(widget.studentId)?.end;
      showSuccess(
        context,
        title: context.tr('تم تفعيل الاشتراك', 'You are subscribed'),
        message: end == null
            ? context.tr(
                'كل الدروس مفتوحة الآن.', 'Every lesson is unlocked now.')
            : context.tr(
                'كل الدروس مفتوحة حتى ${fmtDateYear(context, end)}. مذاكرة موفقة!',
                'Every lesson is unlocked until ${fmtDateYear(context, end)}. Happy studying!'),
        ctaLabel: context.tr('ابدأ المذاكرة', 'Start learning'),
      );
    } else {
      toast(
          context,
          switch (r) {
            'used' => context.tr(
                'هذا الكود مستخدم من قبل', 'This code was already used'),
            'wrong_grade' => context.tr('الكود غير مخصص لصفك الدراسي',
                'This code is for a different grade'),
            _ => context.tr('كود غير صحيح', 'Invalid code'),
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.user(widget.studentId);
    final sub = s.subscriptionOf(widget.studentId);
    final active = sub?.active ?? false;
    final history = s.subscriptions
        .where((x) => x.studentId == widget.studentId)
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final forChild = s.me!.role != UserRole.student;

    return Scaffold(
      appBar: AppBar(
          title: Text(forChild
              ? context.tr(
                  'اشتراك ${st.name.ar}', '${st.name.en} • Subscription')
              : context.tr('الاشتراك', 'Subscription'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          AppCard(
            border: false,
            gradient: LinearGradient(
              colors: active
                  ? const [AppColors.primary, AppColors.primaryDark]
                  : const [Color(0xFF5B6B65), Color(0xFF3B4742)],
            ),
            child: Row(children: [
              Icon(
                  active
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        active
                            ? context.tr('اشتراك فعّال', 'Active subscription')
                            : sub == null
                                ? context.tr(
                                    'لا يوجد اشتراك', 'No subscription')
                                : context.tr(
                                    'انتهى الاشتراك', 'Subscription expired'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        sub == null
                            ? context.tr('الدروس المجانية فقط متاحة',
                                'Only free lessons are available')
                            : active
                                ? context.tr(
                                    '${AppState.plan(sub.planId).name.ar} • حتى ${fmtDateYear(context, sub.end)} (${sub.daysLeft} يوم)',
                                    '${AppState.plan(sub.planId).name.en} • until ${fmtDateYear(context, sub.end)} (${sub.daysLeft} days)')
                                : context.tr(
                                    'انتهى في ${fmtDateYear(context, sub.end)}',
                                    'Ended on ${fmtDateYear(context, sub.end)}'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          SectionHeader(active
              ? context.tr('تمديد الاشتراك', 'Extend subscription')
              : context.tr('اختر خطتك', 'Choose a plan')),
          for (final p in AppState.plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: p,
                onTap: () => showSheet(
                    context,
                    (_) =>
                        _CheckoutSheet(plan: p, studentId: widget.studentId)),
              ),
            ),
          SectionHeader(
              context.tr('لديك كود تفعيل؟', 'Have an activation code?')),
          AppCard(
            child: Column(children: [
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                    hintText: 'XXXX-XXXX',
                    prefixIcon: Icon(Icons.confirmation_number_outlined)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _redeem,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(context.tr('تفعيل الكود', 'Redeem code')),
              ),
            ]),
          ),
          if (history.isNotEmpty) ...[
            SectionHeader(context.tr('سجل الاشتراكات', 'History')),
            for (final h in history)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    IconBadge(Icons.receipt_long_rounded,
                        h.active ? AppColors.leaf : AppColors.muted,
                        size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppState.plan(h.planId).name.of(context),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              '${fmtDate(context, h.start)} → ${fmtDate(context, h.end)} • ${subSourceLabel(context, h.source)}',
                              style: TextStyle(
                                  color: context.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Pill(
                        h.active
                            ? context.tr('فعّال', 'Active')
                            : context.tr('منتهي', 'Expired'),
                        h.active ? AppColors.leaf : AppColors.muted),
                  ]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final perMonth = plan.price / plan.months;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                plan.best ? Border.all(color: AppColors.amber, width: 2) : null,
          ),
          child: AppCard(
            border: !plan.best,
            onTap: onTap,
            child: Row(children: [
              IconBadge(Icons.workspace_premium_rounded,
                  plan.best ? AppColors.amber : AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name.of(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18)),
                    Text(plan.perk.of(context),
                        style: TextStyle(color: context.muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                        context.tr('${money(context, perMonth.round())} / شهر',
                            '${money(context, perMonth.round())} / month'),
                        style: TextStyle(color: context.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(money(context, plan.price),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: context.brand)),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded, color: context.muted),
              ]),
            ]),
          ),
        ),
        if (plan.best)
          PositionedDirectional(
            top: -10,
            end: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(context.tr('الأكثر توفيراً', 'Best value'),
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

class _CheckoutSheet extends StatefulWidget {
  final Plan plan;
  final String studentId;
  const _CheckoutSheet({required this.plan, required this.studentId});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  PayMethod _pay = PayMethod.wallet;
  bool _busy = false;

  Future<void> _confirm() async {
    final s = context.read<AppState>();
    if (s.isCloud) {
      // No payment gateway is connected yet: never grant access
      // for a simulated payment on a real backend.
      Navigator.pop(context);
      toast(
          context,
          context.tr(
              'الدفع الإلكتروني غير مفعّل بعد. استخدم كود التفعيل أو تواصل مع د. راشيا',
              'Online payment is not enabled yet. Use an activation code or contact Dr. Rashia'));
      return;
    }
    setState(() => _busy = true);
    // Simulated gateway round-trip. Replace with Fawry/Paymob.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    s.payForPlan(widget.studentId, widget.plan, _pay);
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    if (!mounted) return;
    final end = s.subscriptionOf(widget.studentId)?.end;
    showSuccess(
      nav.context,
      title: context.tr('تم الدفع بنجاح', 'Payment received'),
      message: end == null
          ? context.tr('اشتراكك فعّال الآن.', 'Your subscription is active.')
          : context.tr(
              'كل الدروس مفتوحة حتى ${fmtDateYear(context, end)}. مذاكرة موفقة!',
              'Every lesson is unlocked until ${fmtDateYear(context, end)}. Happy studying!'),
      ctaLabel: context.tr('ابدأ المذاكرة', 'Start learning'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('تأكيد الاشتراك', 'Confirm subscription'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AppCard(
          child: Row(children: [
            Expanded(
                child: Text('${p.name.of(context)} • ${p.perk.of(context)}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(money(context, p.price),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: context.brand)),
          ]),
        ),
        const SizedBox(height: 12),
        RadioGroup<PayMethod>(
          groupValue: _pay,
          onChanged: (v) => setState(() => _pay = v ?? PayMethod.wallet),
          child: Column(children: [
            for (final m in const [PayMethod.wallet, PayMethod.card])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Radio<PayMethod>(value: m),
                title: Text(payLabel(context, m)),
                onTap: () => setState(() => _pay = m),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(context.tr('ادفع ${money(context, p.price)}',
                  'Pay ${money(context, p.price)}')),
        ),
        const SizedBox(height: 8),
        Text(
            context.tr(
                'الدفع تجريبي في هذه النسخة. اربط بوابة دفع حقيقية قبل النشر.',
                'Payment is simulated in this build. Connect a real gateway before launch.'),
            style: TextStyle(color: context.muted, fontSize: 12)),
      ],
    );
  }
}
