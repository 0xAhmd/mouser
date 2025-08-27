import 'package:equatable/equatable.dart';

class MouseState extends Equatable {
  final double sensitivity;
  final double scrollSensitivity;
  final bool isCommandSending;
  final bool isTextSelecting;
  final String? lastCommand;
  final String? errorMessage;
  final String gestureMode; // 'normal', 'scroll', 'select'

  const MouseState({
    this.sensitivity = 2.5,
    this.scrollSensitivity = 1.0,
    this.isCommandSending = false,
    this.isTextSelecting = false,
    this.lastCommand,
    this.errorMessage,
    this.gestureMode = 'normal',
  });

  MouseState copyWith({
    double? sensitivity,
    double? scrollSensitivity,
    bool? isCommandSending,
    bool? isTextSelecting,
    String? lastCommand,
    String? errorMessage,
    String? gestureMode,
  }) {
    return MouseState(
      sensitivity: sensitivity ?? this.sensitivity,
      scrollSensitivity: scrollSensitivity ?? this.scrollSensitivity,
      isCommandSending: isCommandSending ?? this.isCommandSending,
      isTextSelecting: isTextSelecting ?? this.isTextSelecting,
      lastCommand: lastCommand,
      errorMessage: errorMessage,
      gestureMode: gestureMode ?? this.gestureMode,
    );
  }

  @override
  List<Object?> get props => [
        sensitivity,
        scrollSensitivity,
        isCommandSending,
        isTextSelecting,
        lastCommand,
        errorMessage,
        gestureMode,
      ];
}