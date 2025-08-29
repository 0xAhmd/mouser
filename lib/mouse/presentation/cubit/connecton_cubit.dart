import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/core/cache_manager.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit() : super(const ConnectionState()) {
    _loadSavedPreferences();
  }

  /// Load saved preferences on initialization
  Future<void> _loadSavedPreferences() async {
    try {
      final serverIP = await UserPreferences.getServerIP();
      final serverPort = await UserPreferences.getServerPort();

      emit(state.copyWith(
        serverIP: serverIP,
        serverPort: serverPort,
      ));
    } catch (e) {
      // Handle error if needed, but keep default values
      debugPrint('Error loading preferences: $e');
    }
  }

  /// Update server IP and save to preferences
  Future<void> updateServerIP(String ip) async {
    emit(state.copyWith(serverIP: ip));

    // Save to preferences
    try {
      await UserPreferences.setServerIP(ip);
    } catch (e) {
      debugPrint('Error saving server IP: $e');
    }
  }

  /// Update server port and save to preferences
  Future<void> updateServerPort(int port) async {
    emit(state.copyWith(serverPort: port));

    // Save to preferences
    try {
      await UserPreferences.setServerPort(port);
    } catch (e) {
      debugPrint('Error saving server port: $e');
    }
  }

  /// Test connection with current settings
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

        // Save successful connection settings
        await UserPreferences.saveConnectionSettings(
          serverIP: state.serverIP,
          serverPort: state.serverPort,
        );
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

  /// Disconnect from server
  void disconnect() {
    emit(state.copyWith(
      isConnected: false,
      errorMessage: null,
    ));
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Reset connection settings to defaults
  Future<void> resetToDefaults() async {
    await UserPreferences.clearConnectionSettings();

    const defaultIP = '192.168.1.1';
    const defaultPort = 8080;

    emit(state.copyWith(
      serverIP: defaultIP,
      serverPort: defaultPort,
      isConnected: false,
      errorMessage: null,
    ));
  }
}
