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

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
