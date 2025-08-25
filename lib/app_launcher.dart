
import 'package:flutter/material.dart';
import 'package:mouser/mouse/presentation/screens/main_page.dart';
import 'package:mouser/mouse/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return _homeScreen ??
        Container(
          color: Colors.white,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
  }
}
