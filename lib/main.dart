import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'project_intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Single ThemeNotifier instance — lives for the lifetime of the app
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Mini Project',
          debugShowCheckedModeBanner: false,

          // ── Themes ──────────────────────────────────────────────────────
          themeMode: themeMode,
          theme:     AppTheme.light,
          darkTheme: AppTheme.dark,

          // ── Routes ──────────────────────────────────────────────────────
          initialRoute: '/intro',
          routes: {
            '/':      (context) => const ProjectIntroPage(),
            '/intro': (context) => const ProjectIntroPage(),
            '/login': (context) => const LoginPage(),

            // Pass themeNotifier into HomePage so the toggle button works
            '/home':  (context) => HomePage(themeNotifier: _themeNotifier),
          },
        );
      },
    );
  }
}