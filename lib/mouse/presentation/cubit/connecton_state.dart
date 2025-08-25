import 'package:equatable/equatable.dart';

class ConnectionState extends Equatable {
  final String serverIP;
  final int serverPort;
  final bool isConnected;
  final bool isConnecting;
  final String? errorMessage;

  const ConnectionState({
    this.serverIP = '192.168.1.1',
    this.serverPort = 8080,
    this.isConnected = false,
    this.isConnecting = false,
    this.errorMessage,
  });

  ConnectionState copyWith({
    String? serverIP,
    int? serverPort,
    bool? isConnected,
    bool? isConnecting,
    String? errorMessage,
  }) {
    return ConnectionState(
      serverIP: serverIP ?? this.serverIP,
      serverPort: serverPort ?? this.serverPort,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [serverIP, serverPort, isConnected, isConnecting, errorMessage];
}