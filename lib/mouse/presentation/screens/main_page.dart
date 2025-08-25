// lib/mouse/presentation/screens/main_page.dart
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/keyboard/presentation/pages/keyboard_page.dart';
import 'package:mouser/mouse/presentation/widgets/control_button.dart';
import 'package:mouser/mouse/presentation/widgets/touch_pad_area.dart';
import 'package:mouser/mouse/presentation/widgets/animated_button.dart';
import 'package:mouser/mouse/presentation/widgets/custom_text_field.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_state.dart';

class MouserScreen extends StatefulWidget {
  const MouserScreen({super.key});

  @override
  _MouserScreenState createState() => _MouserScreenState();
}

class _MouserScreenState extends State<MouserScreen> {
  final TextEditingController _ipController = TextEditingController();
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      _buildMousePage(),
      const KeyboardPage(),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionState = context.read<ConnectionCubit>().state;
      _ipController.text = connectionState.serverIP;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ConnectionCubit, ConnectionState>(
              listener: (context, state) {
                if (state.isConnected) {
                  HapticFeedback.lightImpact();
                  _showSnackBar('Connected successfully!', Colors.green);
                } else if (!state.isConnected && !state.isConnecting) {
                  if (state.errorMessage != null) {
                    HapticFeedback.heavyImpact();
                    _showSnackBar(state.errorMessage!, Colors.red);
                  }
                }
              },
            ),
            BlocListener<MouseCubit, MouseState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  _showSnackBar(state.errorMessage!, Colors.red);
                  context.read<MouseCubit>().clearError();
                }
              },
            ),
          ],
          child: _currentIndex == 0
              ? Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: _buildConnectionStatus(),
                    ), // ✅ unified header
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),
                            _buildConnectionCard(theme),
                            SizedBox(height: 20.h),
                            _buildSensitivityCard(theme),
                            SizedBox(height: 20.h),
                            _buildTouchpadCard(theme),
                            SizedBox(height: 20.h),
                            _buildControlButtons(theme),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mouse),
            label: 'Mouse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard),
            label: 'Keyboard',
          ),
        ],
      ),
    );
  }

  Widget _buildMousePage() {
    return const SizedBox(); // Main build handles page
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Row(
            children: [
              Icon(
                connectionState.isConnected ? Icons.wifi : Icons.wifi_off,
                color: connectionState.isConnected ? Colors.green : Colors.red,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionState.isConnected
                          ? 'Connected'
                          : 'Not Connected',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (connectionState.isConnected)
                      Text(
                        connectionState.serverIP,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionCard(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connection',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: _ipController,
                label: 'PC IP Address',
                hint: '192.168.1.1',
                prefixIcon: Icons.router,
                onChanged: (value) {
                  context.read<ConnectionCubit>().updateServerIP(value);
                },
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () {
                    context.read<ConnectionCubit>().testConnection();
                  },
                  isLoading: connectionState.isConnecting,
                  text: connectionState.isConnected ? 'Reconnect' : 'Connect',
                  icon:
                      connectionState.isConnected ? Icons.refresh : Icons.link,
                ),
              ),
              if (connectionState.isConnected) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ConnectionCubit>().disconnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Disconnect',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensitivityCard(ThemeData theme) {
    return BlocBuilder<MouseCubit, MouseState>(
      builder: (context, mouseState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune,
                      color: theme.colorScheme.primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Sensitivity',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      mouseState.sensitivity.toStringAsFixed(1),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.h,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
                ),
                child: Slider(
                  value: mouseState.sensitivity,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  onChanged: (value) {
                    context.read<MouseCubit>().updateSensitivity(value);
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTouchpadCard(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: 300.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TouchpadArea(
              isConnected: connectionState.isConnected,
              onPanUpdate: (details) {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().sendMoveCommand(
                        details.delta.dx,
                        details.delta.dy,
                      );
                }
              },
              onTap: () {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().sendClickCommand('left_click');
                  HapticFeedback.lightImpact();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ControlButton(
                      icon: Icons.mouse,
                      label: 'Left Click',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendClickCommand('left_click')
                          : null,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.menu,
                      label: 'Right Click',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendClickCommand('right_click')
                          : null,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ControlButton(
                      icon: Icons.keyboard_arrow_up,
                      label: 'Scroll Up',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendScrollCommand('scroll_up')
                          : null,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.keyboard_arrow_down,
                      label: 'Scroll Down',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendScrollCommand('scroll_down')
                          : null,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
