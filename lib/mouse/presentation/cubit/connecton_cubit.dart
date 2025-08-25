import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(const ConnectionState());

  void updateServerIP(String ip) {
    emit(state.copyWith(serverIP: ip));
  }

  Future<void> testConnection() async {
    if (state.isConnecting) return;

    emit(state.copyWith(isConnecting: true, errorMessage: null));

    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('http://${state.serverIP}:${state.serverPort}/ping'),
        headers: {'Accept': 'application/json', 'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));

      client.close();

      if (response.statusCode == 200) {
        emit(state.copyWith(
          isConnected: true,
          isConnecting: false,
        ));
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      emit(state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: 'Connection failed: $e',
      ));
    }
  }

  void disconnect() {
    emit(state.copyWith(
      isConnected: false,
      errorMessage: null,
    ));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}