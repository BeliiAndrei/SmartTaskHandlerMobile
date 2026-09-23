import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';

void main() {
  runApp(const SmartTaskHandlerApp());
}

class SmartTaskHandlerApp extends StatelessWidget {
  const SmartTaskHandlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3157D5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartTaskHandler',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E5EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}
