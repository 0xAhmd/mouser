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

  void updateZoomSensitivity(double zoomSensitivity) {
    emit(state.copyWith(zoomSensitivity: zoomSensitivity));
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

  // New enhanced gesture methods
  void sendTwoFingerScroll(double deltaY) {
    // Convert deltaY to scroll commands
    final scrollAmount = deltaY * state.scrollSensitivity;
    final scrollDirection = scrollAmount > 0 ? 'scroll_up' : 'scroll_down';

    // Send multiple scroll events for smooth scrolling
    final scrollCount = (scrollAmount.abs() * 3).round().clamp(1, 5);

    for (int i = 0; i < scrollCount; i++) {
      sendMouseCommand(scrollDirection);
    }
  }

  void sendPinchZoom(double scaleDelta) {
    // Convert pinch gesture to Ctrl+Scroll for zooming
    final zoomAmount = scaleDelta * state.zoomSensitivity;

    if (zoomAmount.abs() > 0.01) {
      final isZoomIn = zoomAmount > 0;

      // Send Ctrl+Scroll combination for zoom
      sendKeyboardCommand('key_hold_start', data: {'key': 'ctrl'});

      // Send scroll events while holding Ctrl
      final scrollDirection = isZoomIn ? 'scroll_up' : 'scroll_down';
      final scrollCount = (zoomAmount.abs() * 5).round().clamp(1, 3);

      for (int i = 0; i < scrollCount; i++) {
        sendMouseCommand(scrollDirection);
      }

      sendKeyboardCommand('key_hold_end', data: {'key': 'ctrl'});
    }
  }

  void sendRightClick() {
    sendMouseCommand('right_click');
  }

  void sendDoubleClick() {
    sendMouseCommand('double_click');
  }

  void startTextSelection() {
    // Start drag selection
    sendMouseCommand('drag_start');
    emit(state.copyWith(isTextSelecting: true));
  }

  void endTextSelection() {
    // End drag selection
    sendMouseCommand('drag_end');
    emit(state.copyWith(isTextSelecting: false));
  }

  void sendTextSelectionMove(double dx, double dy) {
    // Send precise movement for text selection
    sendMouseCommand(
      'move',
      data: {
        'dx': dx * state.sensitivity * 0.3, // Slower movement for precision
        'dy': dy * state.sensitivity * 0.3,
      },
    );
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

  // Smart zoom presets
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

  // Gesture sensitivity presets
  void setGestureSensitivity(String preset) {
    switch (preset) {
      case 'low':
        emit(state.copyWith(
          sensitivity: 0.5,
          scrollSensitivity: 0.3,
          zoomSensitivity: 0.2,
        ));
        break;
      case 'medium':
        emit(state.copyWith(
          sensitivity: 1.0,
          scrollSensitivity: 0.5,
          zoomSensitivity: 0.3,
        ));
        break;
      case 'high':
        emit(state.copyWith(
          sensitivity: 1.8,
          scrollSensitivity: 0.8,
          zoomSensitivity: 0.5,
        ));
        break;
      default:
        // Custom sensitivity values
        break;
    }
  }
}
