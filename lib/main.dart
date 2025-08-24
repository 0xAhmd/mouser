import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mouser/screens/onboarding_screen.dart';
import 'package:mouser/screens/main_page.dart';

void main() {
  runApp(const Mouser());
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
          primary: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Widget? _homeScreen;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasCompletedOnboarding =
        prefs.getBool('onboarding_completed') ?? false;

    setState(() {
      _homeScreen = hasCompletedOnboarding
          ? const MouserScreen()
          : const OnboardingScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _homeScreen ?? Container();
  }
}
