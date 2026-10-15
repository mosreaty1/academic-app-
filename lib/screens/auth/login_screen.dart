import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/seed.dart';
import '../../models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _role = UserRole.student;
  int _grade = 2;
  bool _obscure = true;
  bool _loading = false;
  final _id = TextEditingController();
  final _pass = TextEditingController(text: '123456');

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _demoId(AppState s) {
    switch (_role) {
      case UserRole.student:
        return s.user(Seed.demoStudentByGrade[_grade]!).phone.isNotEmpty
            ? s.user(Seed.demoStudentByGrade[_grade]!).phone
            : 'S-${Seed.demoStudentByGrade[_grade]}';
      case UserRole.parent:
        return s.user('p1').phone;
      case UserRole.teacher:
        return s.user('t1').phone;
    }
  }

  Future<void> _login() async {
    final s = context.read<AppState>();
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    switch (_role) {
      case UserRole.student:
        s.login(s.user(Seed.demoStudentByGrade[_grade]!));
      case UserRole.parent:
        s.login(s.user('p1'));
      case UserRole.teacher:
        s.login(s.user('t1'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    _id.text = _demoId(s);
    final roles = <(UserRole, IconData, String, String)>[
      (UserRole.student, Icons.school_rounded, 'طالب', 'Student'),
      (UserRole.parent, Icons.family_restroom_rounded, 'ولي أمر', 'Parent'),
      (UserRole.teacher, Icons.science_rounded, 'المعلمة', 'Teacher'),
    ];
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => s.setArabic(!s.isAr),
                    icon: const Icon(Icons.translate_rounded,
                        color: Colors.white, size: 18),
                    label: Text(s.isAr ? 'English' : 'العربية',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.biotech_rounded,
                      color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 18),
                Text(context.tr('أهلاً بك 👋', 'Welcome 👋'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                    context.tr('سجّل الدخول إلى أكاديمية د. راشيا للأحياء',
                        'Sign in to Dr. Rashia Biology Academy'),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('أنا...', 'I am a...'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final r in roles)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _RoleTile(
                            icon: r.$2,
                            label: context.tr(r.$3, r.$4),
                            selected: _role == r.$1,
                            onTap: () => setState(() => _role = r.$1),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_role == UserRole.student) ...[
                  const SizedBox(height: 22),
                  Text(context.tr('الصف الدراسي', 'Grade'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final g in const [1, 2, 3])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _GradeTile(
                              label: gradeTiny(context, g),
                              selected: _grade == g,
                              onTap: () => setState(() => _grade = g),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                    _role == UserRole.student
                        ? context.tr('كود الطالب / رقم الموبايل', 'Student ID / phone')
                        : context.tr('رقم الموبايل', 'Phone number'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _id,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_iphone_rounded)),
                ),
                const SizedBox(height: 16),
                Text(context.tr('كلمة المرور', 'Password'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => toast(
                        context,
                        context.tr('سيتم إرسال رمز الاستعادة على موبايلك',
                            'A reset code will be sent to your phone')),
                    child: Text(context.tr('نسيت كلمة المرور؟', 'Forgot password?')),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(context.tr('تسجيل الدخول', 'Sign in')),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: context.brandSoft,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: context.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            context.tr(
                                'نسخة تجريبية: اختر الدور والصف ثم اضغط تسجيل الدخول لاستعراض التطبيق ببيانات تجريبية.',
                                'Demo build: pick a role and grade, then sign in to explore the app with sample data.'),
                            style: const TextStyle(fontSize: 12.5, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? context.cs.primary : context.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? context.cs.primary : context.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon,
                  size: 28, color: selected ? Colors.white : context.brand),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : context.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GradeTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? context.brandSoft : context.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? context.cs.primary : context.line,
            width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: selected ? context.brand : context.ink)),
          ),
        ),
      ),
    );
  }
}
