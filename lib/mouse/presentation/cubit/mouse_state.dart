import 'package:equatable/equatable.dart';

class MouseState extends Equatable {
  final double sensitivity;
  final bool isCommandSending;
  final String? lastCommand;
  final String? errorMessage;

  const MouseState({
    this.sensitivity = 1.0,
    this.isCommandSending = false,
    this.lastCommand,
    this.errorMessage,
  });

  MouseState copyWith({
    double? sensitivity,
    bool? isCommandSending,
    String? lastCommand,
    String? errorMessage,
  }) {
    return MouseState(
      sensitivity: sensitivity ?? this.sensitivity,
      isCommandSending: isCommandSending ?? this.isCommandSending,
      lastCommand: lastCommand,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [sensitivity, isCommandSending, lastCommand, errorMessage];
}