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
            width: widget.width ?? 35.w,
            height: 40.h,
            margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
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
                  borderRadius: BorderRadius.circular(6.r),
                ),
                elevation: widget.isPressed ? 0 : 1,
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 0.5.w,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}