import 'dart:ui';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/keyboard/presentation/pages/keyboard_page.dart';
import 'package:mouser/file_transfer/presentation/pages/file_transfer_page.dart';
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

class _MouserScreenState extends State<MouserScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      _buildMousePage(),
      const KeyboardPage(),
      const FileTransferPage(), // Add file transfer page
    ]);

    // Initialize animation controller for navigation bar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start with navigation bar visible
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionState = context.read<ConnectionCubit>().state;
      _ipController.text = connectionState.serverIP;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showNavBar() {
    if (!_isNavBarVisible) {
      setState(() {
        _isNavBarVisible = true;
      });
      _animationController.forward();
    }
  }

  void _hideNavBar() {
    if (_isNavBarVisible) {
      setState(() {
        _isNavBarVisible = false;
      });
      _animationController.reverse();
    }
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
      body: Stack(
        children: [
          SafeArea(
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
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo is UserScrollNotification) {
                    if (scrollInfo.direction == ScrollDirection.forward) {
                      _showNavBar();
                    } else if (scrollInfo.direction ==
                        ScrollDirection.reverse) {
                      _hideNavBar();
                    }
                  }
                  return false;
                },
                child: _currentIndex == 0
                    ? Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: _buildConnectionStatus(),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Column(
                                children: [
                                  SizedBox(height: 20.h),
                                  _buildConnectionCard(theme),
                                  SizedBox(height: 20.h),
                                  _buildTouchpadCard(theme),
                                  SizedBox(height: 20.h),
                                  _buildSensitivityCard(theme),
                                  SizedBox(height: 20.h),
                                  _buildControlButtons(theme),
                                  SizedBox(height: 20.h),
                                  _buildAdvancedGesturesCard(theme),
                                  SizedBox(height: 80.h),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _pages[_currentIndex],
              ),
            ),
          ),

          // Glassmorphic Bottom Navigation Bar
          Positioned(
            bottom: 24.h,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _animation.value) * 100),
                  child: Opacity(
                    opacity: _animation.value,
                    child: _buildGlassBottomNav(theme),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
                color: const Color.fromARGB(255, 44, 44, 44).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 211, 211, 211).withOpacity(0.1),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.mouse,
                index: 0,
                theme: theme,
              ),
              _buildNavItem(
                icon: Icons.keyboard,
                index: 1,
                theme: theme,
              ),
              _buildNavItem(
                image: "assets/file.png",
                index: 2,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    IconData? icon,
    String? image,
    required int index,
    required ThemeData theme,
  }) {
    final bool isSelected = _currentIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.25 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return GestureDetector(
          onTap: () {
            setState(() => _currentIndex = index);
            _showNavBar();
            HapticFeedback.lightImpact();
          },
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon != null
                    ? Icon(
                        icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 26.sp,
                      )
                    : Image.asset(
                        image!,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        width: 26.sp,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.error,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 26.sp,
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMousePage() {
    return const SizedBox();
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

  Widget _buildTouchpadCard(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: 350.h, // Enhanced touchpad height
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
              onScroll: (deltaY) {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().sendTwoFingerScroll(deltaY);
                  HapticFeedback.selectionClick();
                }
              },
              onRightClick: () {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().sendRightClick();
                  HapticFeedback.mediumImpact();
                }
              },
              onDragStart: () {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().startTextSelection();
                  HapticFeedback.heavyImpact();
                }
              },
              onDragEnd: () {
                if (connectionState.isConnected) {
                  context.read<MouseCubit>().endTextSelection();
                  HapticFeedback.lightImpact();
                }
              },
            ),
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
                    'Gesture Sensitivity',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Gesture sensitivity presets
              Row(
                children: [
                  Expanded(
                    child: _buildSensitivityPreset(
                        'Low', 'low', mouseState, theme),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildSensitivityPreset(
                        'Medium', 'medium', mouseState, theme),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildSensitivityPreset(
                        'High', 'high', mouseState, theme),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Mouse sensitivity (expanded range)
              _buildSensitivitySlider(
                'Mouse',
                mouseState.sensitivity,
                1.0,
                6.0,
                (value) => context.read<MouseCubit>().updateSensitivity(value),
                theme,
                Icons.mouse,
              ),

              SizedBox(height: 16.h),

              // Scroll sensitivity (expanded range)
              _buildSensitivitySlider(
                'Scroll',
                mouseState.scrollSensitivity,
                0.5,
                3.0,
                (value) =>
                    context.read<MouseCubit>().updateScrollSensitivity(value),
                theme,
                Icons.swap_vert,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensitivityPreset(
      String label, String preset, MouseState mouseState, ThemeData theme) {
    final isSelected = _getSelectedPreset(mouseState) == preset;

    return GestureDetector(
      onTap: () {
        context.read<MouseCubit>().setGestureSensitivity(preset);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _getSelectedPreset(MouseState mouseState) {
    if (mouseState.sensitivity == 1.0 && mouseState.scrollSensitivity == 0.5) {
      return 'low';
    } else if (mouseState.sensitivity == 2.5 &&
        mouseState.scrollSensitivity == 1.0) {
      return 'medium';
    } else if (mouseState.sensitivity == 4.5 &&
        mouseState.scrollSensitivity == 1.8) {
      return 'high';
    }
    return 'custom';
  }

  Widget _buildSensitivitySlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    ThemeData theme,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: (newValue) {
              onChanged(newValue);
              HapticFeedback.selectionClick();
            },
          ),
        ),
      ],
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
                      icon: Icons.keyboard_double_arrow_down,
                      label: 'Scroll Down',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendScrollCommand('scroll_down')
                          : null,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.keyboard_double_arrow_up,
                      label: 'Scroll Up',
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<MouseCubit>()
                              .sendScrollCommand('scroll_up')
                          : null,
                      color: Colors.green,
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

  Widget _buildAdvancedGesturesCard(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gesture,
                      color: theme.colorScheme.primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Advanced Shortcuts',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Text manipulation shortcuts
              Row(
                children: [
                  Expanded(
                    child: ControlButton(
                      icon: Icons.content_copy,
                      label: 'Copy',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().copy()
                          : null,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.content_paste,
                      label: 'Paste',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().paste()
                          : null,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Zoom controls (kept as manual buttons)
              Row(
                children: [
                  Expanded(
                    child: ControlButton(
                      icon: Icons.zoom_in,
                      label: 'Zoom In',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().zoomIn()
                          : null,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.zoom_out,
                      label: 'Zoom Out',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().zoomOut()
                          : null,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Additional shortcuts
              Row(
                children: [
                  Expanded(
                    child: ControlButton(
                      icon: Icons.select_all,
                      label: 'Select All',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().selectAll()
                          : null,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ControlButton(
                      icon: Icons.undo,
                      label: 'Undo',
                      onPressed: connectionState.isConnected
                          ? () => context.read<MouseCubit>().undo()
                          : null,
                      color: Colors.red,
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
