import 'package:flutter/material.dart';
import 'package:mouser/screens/main_page.dart';

void main() {
  runApp(Mouser());
}

class Mouser extends StatelessWidget {
  const Mouser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PC Mouse Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: MouserScreen(),
    );
  }
}
