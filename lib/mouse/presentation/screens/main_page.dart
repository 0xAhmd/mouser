import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mouser/mouse/presentation/widgets/control_button.dart';
import 'package:mouser/mouse/presentation/widgets/touch_pad_area.dart';
import 'package:mouser/mouse/presentation/widgets/animated_button.dart';
import 'package:mouser/mouse/presentation/widgets/custom_text_field.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';
import 'package:mouser/mouse/presentation/widgets/status_indicator.dart';
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
    with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _connectionController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize IP controller with current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionState = context.read<ConnectionCubit>().state;
      _ipController.text = connectionState.serverIP;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectionController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ConnectionCubit, ConnectionState>(
              listener: (context, state) {
                if (state.isConnected) {
                  _connectionController.forward();
                  HapticFeedback.lightImpact();
                  _showSnackBar('Connected successfully!', Colors.green);
                } else if (!state.isConnected && !state.isConnecting) {
                  _connectionController.reverse();
                  if (state.errorMessage != null) {
                    HapticFeedback.heavyImpact();
                    _showSnackBar(state.errorMessage!, Colors.red);
                  } else {
                    HapticFeedback.lightImpact();
                    _showSnackBar('Disconnected', Colors.orange);
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
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildConnectionCard(theme),
                      const SizedBox(height: 20),
                      _buildSensitivityCard(theme),
                      const SizedBox(height: 20),
                      _buildTouchpadCard(theme),
                      const SizedBox(height: 20),
                      _buildControlButtons(theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return AnimatedBuilder(
          animation: _connectionController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    connectionState.isConnected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    connectionState.isConnected
                        ? theme.colorScheme.primary.withOpacity(0.8)
                        : theme.colorScheme.error.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (connectionState.isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              _pulseController.value * 0.5 + 0.3,
                            ),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.computer,
                            color: Colors.white, size: 32),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mouse Controller',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey(connectionState.isConnected),
                            connectionState.isConnected
                                ? 'Connected to ${connectionState.serverIP}'
                                : 'Not Connected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusIndicator(isConnected: connectionState.isConnected),
                ],
              ),
            );
          },
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ipController,
                label: 'PC IP Address',
                hint: '192.168.1.1',
                prefixIcon: Icons.router,
                onChanged: (value) {
                  context.read<ConnectionCubit>().updateServerIP(value);
                },
              ),
              const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ConnectionCubit>().disconnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_off),
                        SizedBox(width: 8),
                        Text(
                          'Disconnect',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
                  Icon(Icons.tune, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sensitivity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mouseState.sensitivity.toStringAsFixed(1),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20),
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
          padding: const EdgeInsets.all(0),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
                  const SizedBox(width: 12),
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
