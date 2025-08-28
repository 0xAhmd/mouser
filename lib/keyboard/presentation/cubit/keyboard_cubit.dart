import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mouser/keyboard/data/repo/keyboard_repo.dart';
import 'package:mouser/keyboard/presentation/cubit/keyboard_state.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';

class KeyboardCubit extends Cubit<KeyboardState> {
  final ConnectionCubit _connectionCubit;
  KeyboardRepository? _repository;

  KeyboardCubit({required ConnectionCubit connectionCubit})
      : _connectionCubit = connectionCubit,
        super(const KeyboardState()) {
    _initializeRepository();
  }

  void _initializeRepository() {
    final serverIP = _connectionCubit.state.serverIP;
    final serverPort = _connectionCubit.state.serverPort;
    _repository = KeyboardRepository(
      baseUrl: 'http://$serverIP:$serverPort',
    );
  }

  void updateInputText(String text) {
    emit(state.copyWith(inputText: text));
  }

  void toggleShift() {
    emit(state.copyWith(isShiftPressed: !state.isShiftPressed));
  }

  void toggleCtrl() {
    emit(state.copyWith(isCtrlPressed: !state.isCtrlPressed));
  }

  void toggleAlt() {
    emit(state.copyWith(isAltPressed: !state.isAltPressed));
  }

  Future<void> sendText(String text) async {
    if (!_connectionCubit.state.isConnected || text.isEmpty) return;

    _initializeRepository();
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await _repository?.sendText(text);
      emit(state.copyWith(
        isLoading: false,
        lastAction: 'type: $text',
        inputText: '',
      ));
    } catch (e) {
      debugPrint('Error sending text: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send text: $e',
      ));
    }
  }

  Future<void> sendKey(String key) async {
    if (!_connectionCubit.state.isConnected) return;

    _initializeRepository();
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await _repository?.sendKey(
        key,
        shift: state.isShiftPressed,
        ctrl: state.isCtrlPressed,
        alt: state.isAltPressed,
      );
      emit(state.copyWith(
        isLoading: false,
        lastAction: 'key: $key',
        isShiftPressed: false,
        isCtrlPressed: false,
        isAltPressed: false,
      ));
    } catch (e) {
      debugPrint('Error sending key: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send key: $e',
      ));
    }
  }

  Future<void> sendSpecialKey(String action) async {
    if (!_connectionCubit.state.isConnected) return;

    _initializeRepository();
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      switch (action.toLowerCase()) {
        case 'backspace':
          await _repository?.sendBackspace();
          break;
        case 'enter':
          await _repository?.sendEnter();
          break;
        case 'space':
          await _repository?.sendSpace();
          break;
        case 'tab':
          await _repository?.sendTab();
          break;
        case 'escape':
          await _repository?.sendEscape();
          break;
        case 'print_screen':
          await _repository?.sendPrintScreen();
          break;
        default:
          if (action.contains('arrow')) {
            await _repository?.sendArrowKey(action.replaceAll('_arrow', ''));
          }
      }
      emit(state.copyWith(
        isLoading: false,
        lastAction: 'special: $action',
      ));
    } catch (e) {
      debugPrint('Error sending special key: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send special key: $e',
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
