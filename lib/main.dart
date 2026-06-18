import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NazariaApp());
}

class NazariaApp extends StatelessWidget {
  const NazariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nazaria PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
