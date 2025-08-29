import 'package:flutter/material.dart';
import 'package:mouser/core/cache_manager.dart';
import 'package:mouser/mouse/presentation/screens/main_page.dart';
import 'package:mouser/mouse/presentation/screens/onboarding_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Widget? _homeScreen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app and check onboarding status
  Future<void> _initializeApp() async {
    try {
      // Initialize preferences if not already initialized
      await UserPreferences.init();
      
      // Check onboarding status using the preferences service
      bool hasCompletedOnboarding = await UserPreferences.getOnboardingCompleted();

      if (mounted) {
        setState(() {
          _homeScreen = hasCompletedOnboarding
              ? const MouserScreen()
              : const OnboardingScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      
      // Fallback to onboarding screen if there's an error
      if (mounted) {
        setState(() {
          _homeScreen = const OnboardingScreen();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.computer,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Loading text
              Text(
                'Loading preferences...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _homeScreen ?? Container(
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