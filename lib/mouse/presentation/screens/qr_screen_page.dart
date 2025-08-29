import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _hasPermission = false;
  bool _isProcessing = false;
  String _statusMessage = 'Position QR code in the frame';

  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.linear,
    ));
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    } else {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processScanResult(scanData.code!);
      }
    });
  }

  Future<void> _processScanResult(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing QR code...';
    });

    HapticFeedback.mediumImpact();

    try {
      // Parse QR code data
      // Expected format: {"ip": "192.168.1.100", "port": 8080}
      // or simple format: "192.168.1.100:8080"

      String ip;
      int port;

      if (qrData.contains('{') && qrData.contains('}')) {
        // JSON format
        final data = parseJsonQRData(qrData);
        ip = data['ip'] ?? '';
        port = int.tryParse(data['port']?.toString() ?? '') ?? 8080;
      } else if (qrData.contains(':')) {
        // Simple format: "IP:PORT"
        final parts = qrData.split(':');
        ip = parts[0];
        port = int.tryParse(parts[1]) ?? 8080;
      } else {
        // Just IP, use default port
        ip = qrData;
        port = 8080;
      }

      // Validate IP format
      if (!_isValidIP(ip)) {
        throw Exception('Invalid IP address format');
      }

      setState(() {
        _statusMessage = 'Connecting to $ip:$port...';
      });

      // Update connection settings
      final connectionCubit = context.read<ConnectionCubit>();
      await connectionCubit.updateServerIP(ip);
      await connectionCubit.updateServerPort(port);

      // Attempt connection
      await connectionCubit.testConnection();

      // Wait a bit to see the result
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if connected successfully
      if (context.mounted) {
        final currentState = context.read<ConnectionCubit>().state;
        if (currentState.isConnected) {
          _showSuccessAndReturn('Connected to $ip:$port successfully!');
        } else {
          throw Exception(currentState.errorMessage ?? 'Connection failed');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });

      _showErrorMessage('Failed to connect: ${e.toString()}');

      // Reset after showing error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Position QR code in the frame';
          });
        }
      });
    }
  }

  Map<String, dynamic> parseJsonQRData(String jsonString) {
    try {
      // Simple JSON parsing without importing dart:convert
      jsonString = jsonString.trim();
      if (!jsonString.startsWith('{') || !jsonString.endsWith('}')) {
        throw Exception('Invalid JSON format');
      }

      final content = jsonString.substring(1, jsonString.length - 1);
      final pairs = content.split(',');
      final Map<String, dynamic> result = {};

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().replaceAll('"', '');
          final value = keyValue[1].trim().replaceAll('"', '');
          result[key] = value;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to parse QR code data');
    }
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  void _showSuccessAndReturn(String message) {
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Return to previous screen after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showErrorMessage(String message) {
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasPermission) {
      return _buildPermissionScreen(theme);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: theme.colorScheme.primary,
              borderRadius: 20.r,
              borderLength: 40.w,
              borderWidth: 6.w,
              cutOutSize: 250.w,
            ),
          ),

          // Animated scanning line
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanLinePainter(
                    progress: _scanLineAnimation.value,
                    color: theme.colorScheme.primary,
                    cutOutSize: 250.w,
                  ),
                );
              },
            ),
          ),

          // Top overlay with back button and flash toggle
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),

                  // Flash toggle
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isFlashOn ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: _isFlashOn
                                  ? theme.colorScheme.primary.withOpacity(0.8)
                                  : Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan QR Code to Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isProcessing) ...[
                        SizedBox(height: 16.h),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80.sp,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              SizedBox(height: 24.h),
              Text(
                'Camera Permission Required',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'To scan QR codes and connect to your PC, we need access to your camera.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: () async {
                  final result = await Permission.camera.request();
                  setState(() {
                    _hasPermission = result.isGranted;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Grant Camera Permission',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the scanning line animation
class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double cutOutSize;

  ScanLinePainter({
    required this.progress,
    required this.color,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Calculate the scanning area
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaTop = centerY - cutOutSize / 2;
    final scanAreaBottom = centerY + cutOutSize / 2;
    final scanAreaLeft = centerX - cutOutSize / 2;
    final scanAreaRight = centerX + cutOutSize / 2;

    // Draw the scanning line moving from top to bottom
    final lineY = scanAreaTop + (scanAreaBottom - scanAreaTop) * progress;

    canvas.drawLine(
      Offset(scanAreaLeft, lineY),
      Offset(scanAreaRight, lineY),
      paint,
    );

    // Add gradient effect
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.8),
          color.withOpacity(0.0),
        ],
      ).createShader(
          Rect.fromLTRB(scanAreaLeft, lineY - 10, scanAreaRight, lineY + 10));

    canvas.drawLine(
      Offset(scanAreaLeft, lineY),
      Offset(scanAreaRight, lineY),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
