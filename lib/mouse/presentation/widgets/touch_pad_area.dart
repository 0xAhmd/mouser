import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TouchpadArea extends StatefulWidget {
  final bool isConnected;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onTap;
  final Function(double) onScroll;
  final Function(double) onZoom;
  final VoidCallback onRightClick;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const TouchpadArea({
    super.key,
    required this.isConnected,
    required this.onPanUpdate,
    required this.onTap,
    required this.onScroll,
    required this.onZoom,
    required this.onRightClick,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<TouchpadArea> createState() => _TouchpadAreaState();
}

class _TouchpadAreaState extends State<TouchpadArea> {
  int _pointerCount = 0;
  Offset? _lastPanPosition;
  double _lastScaleValue = 1.0;
  bool _isDragging = false;
  bool _isTextSelecting = false;
  Offset? _textSelectionStart;

  // Gesture detection variables
  late DateTime _lastTapTime;
  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _lastTapTime = DateTime.now();
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _pointerCount++;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() {
      _pointerCount--;
      if (_pointerCount <= 0) {
        _pointerCount = 0;
        _lastPanPosition = null;
        _lastScaleValue = 1.0;
        if (_isDragging) {
          _isDragging = false;
          widget.onDragEnd();
        }
        if (_isTextSelecting) {
          _isTextSelecting = false;
        }
      }
    });
  }

  void _handleTap() {
    if (!widget.isConnected) return;

    final now = DateTime.now();
    final timeDiff = now.difference(_lastTapTime);

    if (timeDiff <= _doubleTapTimeout) {
      // Double tap detected - trigger double click
      widget.onTap(); // This will be changed to double click in the parent
    } else {
      // Single tap - trigger single click
      widget.onTap();
    }

    _lastTapTime = now;
  }

  void _handleTwoFingerTap() {
    if (!widget.isConnected) return;
    widget.onRightClick();
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.isConnected) return;

    if (_pointerCount == 1) {
      _lastPanPosition = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isConnected) return;

    if (_pointerCount == 1) {
      // Single finger - mouse movement
      widget.onPanUpdate(details);
      _lastPanPosition = details.localPosition;
    } else if (_pointerCount == 2) {
      // Two finger scrolling
      if (_lastPanPosition != null) {
        final deltaY = details.localPosition.dy - _lastPanPosition!.dy;

        // Convert vertical movement to scroll
        if (deltaY.abs() > 2.0) {
          // Threshold to avoid jittery scrolling
          final scrollAmount = -deltaY / 20.0; // Negative for natural scrolling
          widget.onScroll(scrollAmount);
        }
      }
      _lastPanPosition = details.localPosition;
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.isConnected) return;
    _lastScaleValue = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isConnected) return;

    if (_pointerCount >= 2) {
      // Pinch to zoom
      final scaleDelta = details.scale - _lastScaleValue;
      if (scaleDelta.abs() > 0.01) {
        // Threshold to avoid jittery zooming
        widget.onZoom(scaleDelta);
        _lastScaleValue = details.scale;
      }
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!widget.isConnected) return;

    // Only start text selection if we have exactly 1 finger
    if (_pointerCount == 1) {
      // Start text selection mode
      setState(() {
        _isTextSelecting = true;
        _textSelectionStart = details.localPosition;
      });

      // Start drag selection with finger count info
      widget.onDragStart();
    } else {
      // Ignore long press for multi-finger gestures
      debugPrint(
          'Long press ignored - $_pointerCount fingers detected, text selection only works with 1 finger');
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.isConnected || !_isTextSelecting) return;

    // Only continue if we still have 1 finger and we're in text selection mode
    if (_pointerCount == 1) {
      // Continue drag selection
      if (_textSelectionStart != null) {
        final deltaX = details.localPosition.dx - _textSelectionStart!.dx;
        final deltaY = details.localPosition.dy - _textSelectionStart!.dy;

        widget.onPanUpdate(DragUpdateDetails(
          delta: Offset(
              deltaX / 5.0, deltaY / 5.0), // Slower movement for precision
          localPosition: details.localPosition,
          globalPosition: details.globalPosition,
        ));
      }
    } else {
      // Cancel text selection if finger count changed
      _handleLongPressEnd(const LongPressEndDetails());
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!widget.isConnected) return;

    if (_isTextSelecting) {
      setState(() {
        _isTextSelecting = false;
        _textSelectionStart = null;
      });

      widget.onDragEnd();
    }
  }

// Also update your gesture hint method:
  String _getGestureHint() {
    if (_pointerCount == 0) {
      return 'Tap to click • Drag to move • Long press (1 finger) to select text';
    } else if (_pointerCount == 1) {
      return _isTextSelecting
          ? 'Selecting text... (1 finger only)'
          : 'Moving cursor...';
    } else if (_pointerCount == 2) {
      return 'Two fingers: Scroll • Pinch to zoom • Tap for right-click';
    } else {
      return 'Multi-touch gesture active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: GestureDetector(
        onTap: _pointerCount == 2 ? _handleTwoFingerTap : _handleTap,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onLongPressStart: _handleLongPressStart,
        onLongPressMoveUpdate: _handleLongPressMoveUpdate,
        onLongPressEnd: _handleLongPressEnd,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _isTextSelecting
                  ? Colors.orange.withOpacity(0.5)
                  : _pointerCount > 0
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Stack(
            children: [
              // Main touchpad content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(
                        _pointerCount > 0 ? 0.2 : 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isTextSelecting
                          ? Icons.text_fields
                          : _pointerCount >= 2
                              ? Icons.gesture
                              : Icons.touch_app,
                      size: 48.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Enhanced Touchpad',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      _getGestureHint(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),

                  // Gesture indicators
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildGestureChip(
                        '1 finger',
                        'Move & Click',
                        _pointerCount == 1,
                        theme,
                      ),
                      _buildGestureChip(
                        '2 fingers',
                        'Scroll & Zoom',
                        _pointerCount == 2,
                        theme,
                      ),
                      _buildGestureChip(
                        'Long press',
                        'Text Select',
                        _isTextSelecting,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),

              // Visual feedback for touch points
              if (_pointerCount > 0)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$_pointerCount finger${_pointerCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureChip(
      String gesture, String action, bool isActive, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(0.2)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            gesture,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            action,
            style: TextStyle(
              fontSize: 8.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
