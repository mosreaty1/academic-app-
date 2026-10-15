import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import 'student_id_card.dart';

class MenuEntry {
  final IconData icon;
  final Color color;
  final String ar;
  final String en;
  final Widget Function() page;
  final int badge;
  const MenuEntry(this.icon, this.color, this.ar, this.en, this.page,
      {this.badge = 0});
}

/// Profile, shortcuts and settings. Each role passes its own [entries].
class MoreScreen extends StatelessWidget {
  final List<MenuEntry> entries;
  const MoreScreen({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.me!;
    final subtitle = switch (me.role) {
      UserRole.student => '${gradeName(context, me.grade)} • ${me.section}',
      UserRole.parent => context.tr('ولي أمر • ${me.childIds.length} أبناء', 'Parent • ${me.childIds.length} children'),
      UserRole.teacher => context.tr('معلمة الأحياء', 'Biology teacher'),
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('المزيد', 'More'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          if (me.role == UserRole.student)
            StudentIdCard(student: me)
          else
          AppCard(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            border: false,
            child: Row(children: [
              Avatar(me.name.initialOf(context), Colors.white.withValues(alpha: 0.25), radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.name.of(context),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                    if (me.phone.isNotEmpty)
                      Text(me.phone,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          SectionHeader(context.tr('الأقسام', 'Sections')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  ListTile(
                    leading: IconBadge(entries[i].icon, entries[i].color, size: 40),
                    title: Text(context.tr(entries[i].ar, entries[i].en),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (entries[i].badge > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${entries[i].badge}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                    onTap: () => go(context, entries[i].page()),
                  ),
                  if (i < entries.length - 1) const Divider(indent: 70),
                ],
              ],
            ),
          ),
          SectionHeader(context.tr('الإعدادات', 'Settings')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                secondary: const IconBadge(Icons.translate_rounded, AppColors.sky, size: 40),
                title: Text(context.tr('اللغة العربية', 'Arabic language'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(context.tr('التبديل بين العربية والإنجليزية', 'Switch between Arabic and English')),
                value: s.isAr,
                onChanged: s.setArabic,
              ),
              const Divider(indent: 70),
              SwitchListTile(
                secondary: const IconBadge(Icons.dark_mode_rounded, AppColors.violet, size: 40),
                title: Text(context.tr('الوضع الداكن', 'Dark mode'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                value: s.themeMode == ThemeMode.dark,
                onChanged: s.setDark,
              ),
              const Divider(indent: 70),
              ListTile(
                leading: const IconBadge(Icons.logout_rounded, AppColors.coral, size: 40),
                title: Text(context.tr('تسجيل الخروج', 'Sign out'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.coral)),
                onTap: () async {
                  final ok = await confirm(
                      context,
                      context.tr('تسجيل الخروج؟', 'Sign out?'),
                      context.tr('يمكنك الدخول مرة أخرى في أي وقت.', 'You can sign back in at any time.'));
                  if (ok) s.logout();
                },
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
                context.tr('أكاديمية د. راشيا للأحياء • الإصدار 1.0', 'Dr. Rashia Biology Academy • v1.0'),
                style: TextStyle(color: context.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
