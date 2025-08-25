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
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    return dio;
  }

  Future<KeyboardResponse> sendText(String text) async {
    final request = KeyboardRequest(
      action: 'type',
      data: KeyboardData(text: text),
    );
    return await _service.sendKeyboardCommand(request);
  }

  Future<KeyboardResponse> sendKey(String key,
      {bool shift = false, bool ctrl = false, bool alt = false}) async {
    final request = KeyboardRequest(
      action: 'key',
      data: KeyboardData(
        key: key,
        shift: shift,
        ctrl: ctrl,
        alt: alt,
      ),
    );
    return await _service.sendKeyboardCommand(request);
  }

  Future<KeyboardResponse> sendBackspace() async {
    return sendKey('BackSpace');
  }

  Future<KeyboardResponse> sendEnter() async {
    return sendKey('Return');
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
    return sendKey('${direction.toLowerCase()}_arrow');
  }
}
