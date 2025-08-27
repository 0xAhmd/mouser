import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'dart:convert';
import 'mouse_state.dart';

class MouseCubit extends Cubit<MouseState> {
  final ConnectionCubit connectionCubit;

  MouseCubit({required this.connectionCubit}) : super(const MouseState());

  void updateSensitivity(double sensitivity) {
    emit(state.copyWith(sensitivity: sensitivity));
  }

  void updateScrollSensitivity(double scrollSensitivity) {
    emit(state.copyWith(scrollSensitivity: scrollSensitivity));
  }

  Future<void> sendMouseCommand(
    String action, {
    Map<String, dynamic>? data,
  }) async {
    if (!connectionCubit.state.isConnected) return;

    try {
      final client = http.Client();
      final response = await client
          .post(
            Uri.parse(
                'http://${connectionCubit.state.serverIP}:${connectionCubit.state.serverPort}/mouse'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: json.encode({'action': action, 'data': data ?? {}}),
          )
          .timeout(const Duration(milliseconds: 500));

      client.close();

      if (response.statusCode == 200) {
        emit(state.copyWith(
          lastCommand: action,
          errorMessage: null,
        ));
      } else {
        debugPrint('Failed to send command: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending command: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        // Update connection status
        connectionCubit.disconnect();
      }
      emit(state.copyWith(
        errorMessage: 'Command failed: $e',
      ));
    }
  }

  // Enhanced keyboard commands for advanced gestures
  Future<void> sendKeyboardCommand(
    String action, {
    Map<String, dynamic>? data,
  }) async {
    if (!connectionCubit.state.isConnected) return;

    try {
      final client = http.Client();
      final response = await client
          .post(
            Uri.parse(
                'http://${connectionCubit.state.serverIP}:${connectionCubit.state.serverPort}/keyboard'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: json.encode({'action': action, 'data': data ?? {}}),
          )
          .timeout(const Duration(milliseconds: 500));

      client.close();

      if (response.statusCode == 200) {
        emit(state.copyWith(
          lastCommand: 'kb_$action',
          errorMessage: null,
        ));
      } else {
        debugPrint('Failed to send keyboard command: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending keyboard command: $e');
      emit(state.copyWith(
        errorMessage: 'Keyboard command failed: $e',
      ));
    }
  }

  void sendMoveCommand(double dx, double dy) {
    sendMouseCommand(
      'move',
      data: {
        'dx': dx * state.sensitivity,
        'dy': dy * state.sensitivity,
      },
    );
  }

  void sendClickCommand(String clickType) {
    sendMouseCommand(clickType);
  }

  void sendScrollCommand(String direction) {
    sendMouseCommand(direction);
  }

  // Enhanced two-finger scroll method
  void sendTwoFingerScroll(double deltaY) {
    // Convert deltaY to scroll commands with enhanced sensitivity
    final scrollAmount = deltaY * state.scrollSensitivity;

    // Use the new gesture endpoint for better handling
    sendGestureCommand('two_finger_scroll', data: {
      'deltaY': scrollAmount,
      'sensitivity': state.scrollSensitivity,
    });
  }

  Future<void> sendGestureCommand(
    String gestureType, {
    Map<String, dynamic>? data,
  }) async {
    if (!connectionCubit.state.isConnected) return;

    try {
      final client = http.Client();
      final response = await client
          .post(
            Uri.parse(
                'http://${connectionCubit.state.serverIP}:${connectionCubit.state.serverPort}/gesture'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: json.encode({'type': gestureType, 'data': data ?? {}}),
          )
          .timeout(const Duration(milliseconds: 500));

      client.close();

      if (response.statusCode == 200) {
        emit(state.copyWith(
          lastCommand: 'gesture_$gestureType',
          errorMessage: null,
        ));
      } else {
        debugPrint('Failed to send gesture command: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending gesture command: $e');
      emit(state.copyWith(
        errorMessage: 'Gesture command failed: $e',
      ));
    }
  }

  void sendRightClick() {
    sendMouseCommand('right_click');
  }

  void sendDoubleClick() {
    sendMouseCommand('double_click');
  }

  void startTextSelection({int fingerCount = 1}) {
    // Only start text selection for single finger
    if (fingerCount == 1) {
      sendMouseCommand('drag_start', data: {
        'selection_mode': true,
        'finger_count': fingerCount,
      });
      emit(state.copyWith(isTextSelecting: true));
    } else {
      debugPrint(
          'Text selection ignored for $fingerCount fingers - only works with 1 finger');
    }
  }

  void endTextSelection() {
    // End drag selection
    sendMouseCommand('drag_end');
    emit(state.copyWith(isTextSelecting: false));
  }

  void sendTextSelectionMove(double dx, double dy, {int fingerCount = 1}) {
    // Only send text selection moves for single finger
    if (fingerCount == 1) {
      sendMouseCommand(
        'move',
        data: {
          'dx': dx * state.sensitivity * 0.3, // Slower movement for precision
          'dy': dy * state.sensitivity * 0.3,
          'finger_count': fingerCount,
        },
      );
    }
  }

  // Additional keyboard shortcuts for advanced text selection
  void selectAll() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'a']
    });
  }

  void copy() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'c']
    });
  }

  void paste() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'v']
    });
  }

  void cut() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'x']
    });
  }

  void undo() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'z']
    });
  }

  void redo() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', 'y']
    });
  }

  // Basic zoom presets (kept for manual zoom buttons)
  void zoomIn() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', '+']
    });
  }

  void zoomOut() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', '-']
    });
  }

  void resetZoom() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['ctrl', '0']
    });
  }

  // Three-finger gestures (if supported in future)
  void showDesktop() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['cmd', 'd']
    }); // Mac
    // For Windows: Win+D
    // sendKeyboardCommand('key_combination', {'keys': ['win', 'd']});
  }

  void showApplicationSwitcher() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['cmd', 'tab']
    }); // Mac
    // For Windows: Alt+Tab
    // sendKeyboardCommand('key_combination', {'keys': ['alt', 'tab']});
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  // Gesture sensitivity presets (removed zoom sensitivity)
  void setGestureSensitivity(String preset) {
    switch (preset) {
      case 'low':
        emit(state.copyWith(
          sensitivity: 1.0,
          scrollSensitivity: 0.5,
        ));
        break;
      case 'medium':
        emit(state.copyWith(
          sensitivity: 2.5,
          scrollSensitivity: 1.0,
        ));
        break;
      case 'high':
        emit(state.copyWith(
          sensitivity: 4.5,
          scrollSensitivity: 1.8,
        ));
        break;
      default:
        // Custom sensitivity values
        break;
    }
  }
}