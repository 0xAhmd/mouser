import 'package:equatable/equatable.dart';

class KeyboardState extends Equatable {
  final bool isLoading;
  final String inputText;
  final bool isShiftPressed;
  final bool isCtrlPressed;
  final bool isAltPressed;
  final String? errorMessage;
  final String? lastAction;

  const KeyboardState({
    this.isLoading = false,
    this.inputText = '',
    this.isShiftPressed = false,
    this.isCtrlPressed = false,
    this.isAltPressed = false,
    this.errorMessage,
    this.lastAction,
  });

  KeyboardState copyWith({
    bool? isLoading,
    String? inputText,
    bool? isShiftPressed,
    bool? isCtrlPressed,
    bool? isAltPressed,
    String? errorMessage,
    String? lastAction,
  }) {
    return KeyboardState(
      isLoading: isLoading ?? this.isLoading,
      inputText: inputText ?? this.inputText,
      isShiftPressed: isShiftPressed ?? this.isShiftPressed,
      isCtrlPressed: isCtrlPressed ?? this.isCtrlPressed,
      isAltPressed: isAltPressed ?? this.isAltPressed,
      errorMessage: errorMessage,
      lastAction: lastAction,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        inputText,
        isShiftPressed,
        isCtrlPressed,
        isAltPressed,
        errorMessage,
        lastAction,
      ];
}