import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/seed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  final _id = TextEditingController(text: 'RB2-1001');
  final _pass = TextEditingController(text: Seed.demoPassword);

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _errorText(BuildContext c, String code) {
    switch (code) {
      case 'not_found':
        return c.tr('كود الطالب أو رقم الموبايل غير مسجل', 'Student ID or phone number not found');
      case 'wrong_password':
        return c.tr('كلمة المرور غير صحيحة', 'Incorrect password');
      case 'invalid':
        return c.tr('الكود أو كلمة المرور غير صحيحة', 'Incorrect ID or password');
      case 'network':
        return c.tr('تعذر الاتصال. تحقق من الإنترنت', 'Network error. Check your connection');
      default:
        return c.tr('تعذر تسجيل الدخول. حاول مرة أخرى', 'Could not sign in. Please try again');
    }
  }

  Future<void> _login() async {
    final s = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await s.signIn(_id.text, _pass.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = _errorText(context, err);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
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
                Text(context.tr('أهلاً بك','Welcome'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700)),
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
                Text(context.tr('كود الطالب / رقم الموبايل', 'Student ID / phone number'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _id,
                  textDirection: TextDirection.ltr,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'RB2-1001',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    helperText: context.tr('الطالب يدخل بكود الطالب، وولي الأمر والمعلمة برقم الموبايل',
                        'Students use their Student ID; parents and teachers use their phone'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.tr('كلمة المرور', 'Password'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
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
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.coral, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w700))),
                    ]),
                  ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => toast(
                        context,
                        context.tr('تواصل مع د. راشيا لإعادة تعيين كلمة المرور',
                            'Contact Dr. Rashia to reset your password')),
                    child: Text(context.tr('نسيت كلمة المرور؟', 'Forgot password?')),
                  ),
                ),
                const SizedBox(height: 10),
                if (!s.isCloud) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: context.brandSoft,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline_rounded, color: context.brand, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                context.tr('وضع تجريبي (Firebase غير مفعّل). اختر حساباً للتجربة، كلمة المرور ${Seed.demoPassword}',
                                    'Demo mode (Firebase not connected). Tap an account; password is ${Seed.demoPassword}'),
                                style: const TextStyle(fontSize: 12.5, height: 1.5)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final d in Seed.demoLogins)
                            ActionChip(
                              label: Text(context.tr(d.$2, d.$3)),
                              onPressed: () => setState(() {
                                _id.text = d.$1;
                                _pass.text = Seed.demoPassword;
                              }),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
