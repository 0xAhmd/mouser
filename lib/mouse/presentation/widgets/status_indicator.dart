import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;

  const StatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        isConnected ? Icons.wifi : Icons.wifi_off,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }
}
