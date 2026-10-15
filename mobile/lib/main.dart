import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_theme.dart';
import 'package:digisaka/features/auth/presentation/pages/login_screen.dart';

void main() {
  runApp(const DigisakaApp());
}

class DigisakaApp extends StatelessWidget {
  const DigisakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digisaka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}