import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VirtualKey extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final bool isPressed;
  final Color? backgroundColor;

  const VirtualKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.isPressed = false,
    this.backgroundColor,
  });

  @override
  State<VirtualKey> createState() => _VirtualKeyState();
}

class _VirtualKeyState extends State<VirtualKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? 45.w,
            height: 45.h,
            margin: EdgeInsets.all(2.w),
            child: ElevatedButton(
              onPressed: widget.onPressed == null
                  ? null
                  : () {
                      _controller.forward().then((_) => _controller.reverse());
                      widget.onPressed!();
                      HapticFeedback.lightImpact();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPressed
                    ? theme.colorScheme.primary
                    : widget.backgroundColor ?? theme.colorScheme.surface,
                foregroundColor: widget.isPressed
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: widget.isPressed ? 0 : 2,
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}