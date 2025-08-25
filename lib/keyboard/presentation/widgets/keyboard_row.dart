import 'package:flutter/material.dart';
import 'virtual_key.dart';

class KeyboardRow extends StatelessWidget {
  final List<String> keys;
  final Function(String) onKeyPressed;
  final Set<String> pressedKeys;
  final bool isShiftPressed;

  const KeyboardRow({
    super.key,
    required this.keys,
    required this.onKeyPressed,
    this.pressedKeys = const {},
    this.isShiftPressed = false,
  });

  String _getDisplayKey(String key) {
    if (!isShiftPressed) return key.toLowerCase();
    
    const shiftMap = {
      '1': '!', '2': '@', '3': '#', '4': '\$', '5': '%',
      '6': '^', '7': '&', '8': '*', '9': '(', '0': ')',
      '-': '_', '=': '+', '[': '{', ']': '}',
      ';': ':', "'": '"', ',': '<', '.': '>', '/': '?',
    };
    
    return shiftMap[key.toLowerCase()] ?? key.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return VirtualKey(
          label: _getDisplayKey(key),
          onPressed: () => onKeyPressed(key),
          isPressed: pressedKeys.contains(key),
        );
      }).toList(),
    );
  }
}