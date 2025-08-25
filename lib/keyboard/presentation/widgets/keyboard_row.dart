import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  double _calculateKeyWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 64.w; // Account for padding and margins
    final keyCount = keys.length;
    final totalMargin = (keyCount * 4.w); // 2w margin on each side per key
    final keyWidth = (availableWidth - totalMargin) / keyCount;
    
    // Ensure minimum width and maximum width constraints
    return keyWidth.clamp(30.w, 50.w);
  }

  @override
  Widget build(BuildContext context) {
    final keyWidth = _calculateKeyWidth(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) {
          return VirtualKey(
            label: _getDisplayKey(key),
            width: keyWidth,
            onPressed: () => onKeyPressed(key),
            isPressed: pressedKeys.contains(key),
          );
        }).toList(),
      ),
    );
  }
}