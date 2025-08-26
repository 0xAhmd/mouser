import 'package:equatable/equatable.dart';

class MouseState extends Equatable {
  final double sensitivity;
  final double scrollSensitivity;
  final double zoomSensitivity;
  final bool isCommandSending;
  final bool isTextSelecting;
  final String? lastCommand;
  final String? errorMessage;
  final String gestureMode; // 'normal', 'scroll', 'zoom', 'select'

  const MouseState({
    this.sensitivity = 1.0,
    this.scrollSensitivity = 0.5,
    this.zoomSensitivity = 0.3,
    this.isCommandSending = false,
    this.isTextSelecting = false,
    this.lastCommand,
    this.errorMessage,
    this.gestureMode = 'normal',
  });

  MouseState copyWith({
    double? sensitivity,
    double? scrollSensitivity,
    double? zoomSensitivity,
    bool? isCommandSending,
    bool? isTextSelecting,
    String? lastCommand,
    String? errorMessage,
    String? gestureMode,
  }) {
    return MouseState(
      sensitivity: sensitivity ?? this.sensitivity,
      scrollSensitivity: scrollSensitivity ?? this.scrollSensitivity,
      zoomSensitivity: zoomSensitivity ?? this.zoomSensitivity,
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
        zoomSensitivity,
        isCommandSending,
        isTextSelecting,
        lastCommand,
        errorMessage,
        gestureMode,
      ];
}
