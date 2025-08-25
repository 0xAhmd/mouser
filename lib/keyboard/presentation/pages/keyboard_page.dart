// lib/keyboard_feat/presentation/pages/keyboard_page.dart
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/keyboard/presentation/cubit/keyboard_cubit.dart';
import 'package:mouser/keyboard/presentation/cubit/keyboard_state.dart';
import 'package:mouser/keyboard/presentation/widgets/virtual_key.dart';
import 'package:mouser/keyboard/presentation/widgets/keyboard_row.dart';
import 'package:mouser/keyboard/presentation/widgets/text_input_area.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final TextEditingController _textController = TextEditingController();

  final List<List<String>> _keyboardLayout = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'"],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/'],
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Virtual Keyboard',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocListener<KeyboardCubit, KeyboardState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnackBar(state.errorMessage!, Colors.red);
              context.read<KeyboardCubit>().clearError();
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConnectionStatus(),
                SizedBox(height: 16.h),
                _buildTextInputArea(),
                SizedBox(height: 20.h),
                _buildVirtualKeyboard(),
                SizedBox(height: 16.h),
                _buildSpecialKeys(),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildTextInputArea() {
    return BlocBuilder<KeyboardCubit, KeyboardState>(
      builder: (context, keyboardState) {
        return BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, connectionState) {
            return GlassCard(
              child: TextInputArea(
                controller: _textController,
                isLoading: keyboardState.isLoading,
                onSend: connectionState.isConnected
                    ? () {
                        if (_textController.text.isNotEmpty) {
                          context
                              .read<KeyboardCubit>()
                              .sendText(_textController.text);
                          _textController.clear();
                        }
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVirtualKeyboard() {
    return BlocBuilder<KeyboardCubit, KeyboardState>(
      builder: (context, keyboardState) {
        return BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, connectionState) {
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Virtual Keyboard',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Modifier keys
                  _buildModifierKeys(keyboardState, connectionState),
                  SizedBox(height: 12.h),

                  // Keyboard rows
                  ..._keyboardLayout.map((row) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: KeyboardRow(
                        keys: row,
                        isShiftPressed: keyboardState.isShiftPressed,
                        onKeyPressed: connectionState.isConnected
                            ? (key) =>
                                context.read<KeyboardCubit>().sendKey(key)
                            : (_) {},
                      ),
                    );
                  }),

                  SizedBox(height: 12.h),

                  // Space bar
                  Center(
                    child: VirtualKey(
                      label: 'Space',
                      width: 200.w,
                      onPressed: connectionState.isConnected
                          ? () => context
                              .read<KeyboardCubit>()
                              .sendSpecialKey('space')
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModifierKeys(
      KeyboardState keyboardState, ConnectionState connectionState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        VirtualKey(
          label: 'Shift',
          width: 60.w,
          isPressed: keyboardState.isShiftPressed,
          backgroundColor: keyboardState.isShiftPressed
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: connectionState.isConnected
              ? () => context.read<KeyboardCubit>().toggleShift()
              : null,
        ),
        VirtualKey(
          label: 'Ctrl',
          width: 50.w,
          isPressed: keyboardState.isCtrlPressed,
          backgroundColor: keyboardState.isCtrlPressed
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: connectionState.isConnected
              ? () => context.read<KeyboardCubit>().toggleCtrl()
              : null,
        ),
        VirtualKey(
          label: 'Alt',
          width: 50.w,
          isPressed: keyboardState.isAltPressed,
          backgroundColor: keyboardState.isAltPressed
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: connectionState.isConnected
              ? () => context.read<KeyboardCubit>().toggleAlt()
              : null,
        ),
      ],
    );
  }

  Widget _buildSpecialKeys() {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Special Keys',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // Function keys row 1
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  VirtualKey(
                    label: 'Tab',
                    onPressed: connectionState.isConnected
                        ? () =>
                            context.read<KeyboardCubit>().sendSpecialKey('tab')
                        : null,
                  ),
                  VirtualKey(
                    label: 'Enter',
                    onPressed: connectionState.isConnected
                        ? () => context
                            .read<KeyboardCubit>()
                            .sendSpecialKey('enter')
                        : null,
                  ),
                  VirtualKey(
                    label: '⌫',
                    onPressed: connectionState.isConnected
                        ? () => context
                            .read<KeyboardCubit>()
                            .sendSpecialKey('backspace')
                        : null,
                  ),
                  VirtualKey(
                    label: 'Esc',
                    onPressed: connectionState.isConnected
                        ? () => context
                            .read<KeyboardCubit>()
                            .sendSpecialKey('escape')
                        : null,
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Arrow keys
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      VirtualKey(
                        label: '↑',
                        onPressed: connectionState.isConnected
                            ? () => context
                                .read<KeyboardCubit>()
                                .sendSpecialKey('up_arrow')
                            : null,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VirtualKey(
                            label: '←',
                            onPressed: connectionState.isConnected
                                ? () => context
                                    .read<KeyboardCubit>()
                                    .sendSpecialKey('left_arrow')
                                : null,
                          ),
                          VirtualKey(
                            label: '↓',
                            onPressed: connectionState.isConnected
                                ? () => context
                                    .read<KeyboardCubit>()
                                    .sendSpecialKey('down_arrow')
                                : null,
                          ),
                          VirtualKey(
                            label: '→',
                            onPressed: connectionState.isConnected
                                ? () => context
                                    .read<KeyboardCubit>()
                                    .sendSpecialKey('right_arrow')
                                : null,
                          ),
                        ],
                      ),
                    ],
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
