import 'package:dio/dio.dart';
import 'package:mouser/keyboard/data/models/keyboard_request.dart';
import 'package:mouser/keyboard/data/models/keyboard_response.dart';
import 'package:mouser/keyboard/data/service/keyboard_service.dart';

class KeyboardRepository {
  final KeyboardService _service;

  KeyboardRepository({required String baseUrl})
      : _service = KeyboardService(_createDio(baseUrl));

  static Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('DIO: $obj'),
    ));

    return dio;
  }

  Future<KeyboardResponse> sendText(String text) async {
    try {
      final request = KeyboardRequest(
        action: 'type',
        data: KeyboardData(text: text),
      );
      print('Sending text request: ${request.toJson()}');
      return await _service.sendKeyboardCommand(request);
    } catch (e) {
      print('Error in sendText: $e');
      rethrow;
    }
  }

  Future<KeyboardResponse> sendKey(String key,
      {bool shift = false, bool ctrl = false, bool alt = false}) async {
    try {
      final request = KeyboardRequest(
        action: 'key', // Changed from 'key_press' to 'key'
        data: KeyboardData(
          key: key,
          shift: shift,
          ctrl: ctrl,
          alt: alt,
        ),
      );
      print('Sending key request: ${request.toJson()}');
      return await _service.sendKeyboardCommand(request);
    } catch (e) {
      print('Error in sendKey: $e');
      rethrow;
    }
  }

  Future<KeyboardResponse> sendBackspace() async {
    return sendKey('BackSpace'); // Use exact Flutter key name
  }

  Future<KeyboardResponse> sendEnter() async {
    return sendKey('Return'); // Use exact Flutter key name
  }

  Future<KeyboardResponse> sendSpace() async {
    return sendKey('space');
  }

  Future<KeyboardResponse> sendTab() async {
    return sendKey('Tab');
  }

  Future<KeyboardResponse> sendEscape() async {
    return sendKey('Escape');
  }

  Future<KeyboardResponse> sendArrowKey(String direction) async {
    // Send arrow keys in the format the server expects
    return sendKey('${direction.toLowerCase()}_arrow');
  }

  // Additional convenience methods
  Future<KeyboardResponse> sendKeyCombo(List<String> keys) async {
    try {
      final request = KeyboardRequest(
        action: 'key_combination',
        data: KeyboardData(text: keys.join('+')), // For logging purposes
      );
      
      // Override the toJson to include keys array
      final requestJson = request.toJson();
      requestJson['data'] = {'keys': keys};
      
      print('Sending key combination: $requestJson');
      return await _service.sendKeyboardCommand(request);
    } catch (e) {
      print('Error in sendKeyCombo: $e');
      rethrow;
    }
  }

  // Common key combinations
  Future<KeyboardResponse> sendCopy() async {
    return sendKeyCombo(['ctrl', 'c']);
  }

  Future<KeyboardResponse> sendPaste() async {
    return sendKeyCombo(['ctrl', 'v']);
  }

  Future<KeyboardResponse> sendCut() async {
    return sendKeyCombo(['ctrl', 'x']);
  }

  Future<KeyboardResponse> sendUndo() async {
    return sendKeyCombo(['ctrl', 'z']);
  }

  Future<KeyboardResponse> sendRedo() async {
    return sendKeyCombo(['ctrl', 'y']);
  }

  Future<KeyboardResponse> sendSelectAll() async {
    return sendKeyCombo(['ctrl', 'a']);
  }

  Future<KeyboardResponse> sendAltTab() async {
    return sendKeyCombo(['alt', 'tab']);
  }
}