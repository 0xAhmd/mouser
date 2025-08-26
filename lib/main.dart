import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/app_launcher.dart';
import 'package:mouser/keyboard/presentation/cubit/keyboard_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_cubit.dart';
import 'package:mouser/file_transfer/presentation/cubit/file_transfer_cubit.dart';

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
        BlocProvider(
          create: (context) => KeyboardCubit(
            connectionCubit: context.read<ConnectionCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => FileTransferCubit(
            connectionCubit: context.read<ConnectionCubit>(),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
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
        },
      ),
    );
  }
}
