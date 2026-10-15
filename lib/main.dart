import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/app_state.dart';
import 'models/models.dart';
import 'services/firebase_cloud.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/shell/parent_shell.dart';
import 'screens/shell/student_shell.dart';
import 'screens/shell/teacher_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase when configured (see FIREBASE_SETUP.md), offline demo otherwise.
  final cloud = await FirebaseCloud.tryInit();
  final state = AppState.seeded(cloud: cloud);
  if (cloud != null) {
    final saved = await cloud.currentUser();
    if (saved != null) {
      state.users.add(saved);
      try {
        await cloud.load(state..me = saved);
        state.login(saved);
      } catch (_) {
        state.me = null;
      }
    }
  }

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const RashiaApp(),
    ),
  );
}

class RashiaApp extends StatelessWidget {
  const RashiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'Dr. Rashia Biology',
      debugShowCheckedModeBanner: false,
      locale: Locale(s.isAr ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: s.themeMode,
      home: const _Gate(),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select<AppState, UserProfile?>((s) => s.me);
    Widget child;
    if (!_splashDone) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (me == null) {
      child = const LoginScreen(key: ValueKey('login'));
    } else {
      switch (me.role) {
        case UserRole.student:
          child = StudentShell(key: ValueKey(me.id));
        case UserRole.parent:
          child = ParentShell(key: ValueKey(me.id));
        case UserRole.teacher:
          child = TeacherShell(key: ValueKey(me.id));
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}
