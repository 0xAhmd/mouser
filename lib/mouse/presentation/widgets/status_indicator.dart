import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;

  const StatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isConnected ? Icons.wifi : Icons.wifi_off,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
