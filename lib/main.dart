import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mouser/mouse/presentation/screens/onboarding_screen.dart';
import 'package:mouser/mouse/presentation/screens/main_page.dart';

void main() {
  runApp(const Mouser());
}

class Mouser extends StatelessWidget {
  const Mouser({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ConnectionCubit()),
        BlocProvider(
          create: (context) => MouseCubit(
            connectionCubit: context.read<ConnectionCubit>(),
          ),
        ),
      ],
      child: MaterialApp(
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
      ),
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
