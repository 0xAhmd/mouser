import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/core/cache_manager.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'dart:convert';
import 'mouse_state.dart';

class MouseCubit extends Cubit<MouseState> {
  final ConnectionCubit connectionCubit;

  MouseCubit({required this.connectionCubit}) : super(const MouseState()) {
    _loadSavedPreferences();
  }

  /// Load saved sensitivity preferences on initialization
  Future<void> _loadSavedPreferences() async {
    try {
      final mouseSensitivity = await UserPreferences.getMouseSensitivity();
      final scrollSensitivity = await UserPreferences.getScrollSensitivity();
      
      emit(state.copyWith(
        sensitivity: mouseSensitivity,
        scrollSensitivity: scrollSensitivity,
      ));
    } catch (e) {
      debugPrint('Error loading mouse preferences: $e');
    }
  }

  /// Update mouse sensitivity and save to preferences
  Future<void> updateSensitivity(double sensitivity) async {
    emit(state.copyWith(sensitivity: sensitivity));
    
    // Save to preferences
    try {
      await UserPreferences.setMouseSensitivity(sensitivity);
    } catch (e) {
      debugPrint('Error saving mouse sensitivity: $e');
    }
  }

  /// Update scroll sensitivity and save to preferences
  Future<void> updateScrollSensitivity(double scrollSensitivity) async {
    emit(state.copyWith(scrollSensitivity: scrollSensitivity));
    
    // Save to preferences
    try {
      await UserPreferences.setScrollSensitivity(scrollSensitivity);
    } catch (e) {
      debugPrint('Error saving scroll sensitivity: $e');
    }
  }

  /// Set gesture sensitivity preset and save to preferences
  Future<void> setGestureSensitivity(String preset) async {
    double mouseSens;
    double scrollSens;
    
    switch (preset) {
      case 'low':
        mouseSens = 1.0;
        scrollSens = 0.5;
        break;
      case 'medium':
        mouseSens = 2.5;
        scrollSens = 1.0;
        break;
      case 'high':
        mouseSens = 4.5;
        scrollSens = 1.8;
        break;
      default:
        return; // Unknown preset
    }
    
    emit(state.copyWith(
      sensitivity: mouseSens,
      scrollSensitivity: scrollSens,
    ));
    
    // Save both settings to preferences
    try {
      await UserPreferences.saveSensitivitySettings(
        mouseSensitivity: mouseSens,
        scrollSensitivity: scrollSens,
      );
    } catch (e) {
      debugPrint('Error saving sensitivity preset: $e');
    }
  }

  /// Reset sensitivity settings to defaults
  Future<void> resetSensitivityToDefaults() async {
    await UserPreferences.clearSensitivitySettings();
    
    const defaultMouseSensitivity = 2.5;
    const defaultScrollSensitivity = 1.0;
    
    emit(state.copyWith(
      sensitivity: defaultMouseSensitivity,
      scrollSensitivity: defaultScrollSensitivity,
    ));
  }

  // ... (keep all existing methods below this point)

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
        connectionCubit.disconnect();
      }
      emit(state.copyWith(
        errorMessage: 'Command failed: $e',
      ));
    }
  }

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

  void sendTwoFingerScroll(double deltaY) {
    final scrollAmount = deltaY * state.scrollSensitivity;

    sendGestureCommand('two_finger_scroll', data: {
      'deltaY': scrollAmount,
      'sensitivity': state.scrollSensitivity,
    });
  }

  void sendRightClick() {
    sendMouseCommand('right_click');
  }

  void sendDoubleClick() {
    sendMouseCommand('double_click');
  }

  void startTextSelection({int fingerCount = 1}) {
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
    sendMouseCommand('drag_end');
    emit(state.copyWith(isTextSelecting: false));
  }

  void sendTextSelectionMove(double dx, double dy, {int fingerCount = 1}) {
    if (fingerCount == 1) {
      sendMouseCommand(
        'move',
        data: {
          'dx': dx * state.sensitivity * 0.3,
          'dy': dy * state.sensitivity * 0.3,
          'finger_count': fingerCount,
        },
      );
    }
  }

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

  void showDesktop() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['cmd', 'd']
    });
  }

  void showApplicationSwitcher() {
    sendKeyboardCommand('key_combination', data: {
      'keys': ['cmd', 'tab']
    });
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}