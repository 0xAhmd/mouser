import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/widgets/control_button.dart';
import 'package:mouser/widgets/touch_pad_area.dart';
import 'package:mouser/widgets/animated_button.dart';
import 'dart:convert';

import 'package:mouser/widgets/custom_text_field.dart';
import 'package:mouser/widgets/glass_card.dart';
import 'package:mouser/widgets/status_indicator.dart';

class MouserScreen extends StatefulWidget {
  const MouserScreen({super.key});

  @override
  _MouserScreenState createState() => _MouserScreenState();
}

class _MouserScreenState extends State<MouserScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  String serverIP = '192.168.1.100';
  int serverPort = 8080;
  bool isConnected = false;
  double sensitivity = 1.0;
  bool isConnecting = false;

  late AnimationController _pulseController;
  late AnimationController _connectionController;

  @override
  void initState() {
    super.initState();
    _ipController.text = serverIP;
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectionController.dispose();
    super.dispose();
  }

  Future<void> sendMouseCommand(
    String action, {
    Map<String, dynamic>? data,
  }) async {
    if (!isConnected) return;

    try {
      final client = http.Client();
      final response = await client
          .post(
            Uri.parse('http://$serverIP:$serverPort/mouse'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: json.encode({'action': action, 'data': data ?? {}}),
          )
          .timeout(const Duration(milliseconds: 500));

      client.close();

      if (response.statusCode != 200) {
        debugPrint('Failed to send command: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending command: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        setState(() {
          isConnected = false;
        });
        _connectionController.reverse();
      }
    }
  }

  Future<void> testConnection() async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
      serverIP = _ipController.text.trim();
    });

    HapticFeedback.lightImpact();

    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse('http://$serverIP:$serverPort/ping'),
            headers: {'Accept': 'application/json', 'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));

      client.close();

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });
        _connectionController.forward();
        HapticFeedback.lightImpact();
        _showSnackBar('Connected successfully!', Colors.green);
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
      _connectionController.reverse();
      HapticFeedback.heavyImpact();
      _showSnackBar('Connection failed', Colors.red);
    } finally {
      setState(() {
        isConnecting = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildConnectionCard(theme),
                    const SizedBox(height: 20),
                    _buildSensitivityCard(theme),
                    const SizedBox(height: 20),
                    _buildTouchpadCard(theme),
                    const SizedBox(height: 20),
                    _buildControlButtons(theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return AnimatedBuilder(
      animation: _connectionController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isConnected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                isConnected
                    ? theme.colorScheme.primary.withOpacity(0.8)
                    : theme.colorScheme.error.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error)
                        .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          _pulseController.value * 0.5 + 0.3,
                        ),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.computer, color: Colors.white, size: 32),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mouse Controller',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        key: ValueKey(isConnected),
                        isConnected
                            ? 'Connected to $serverIP'
                            : 'Not Connected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StatusIndicator(isConnected: isConnected),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionCard(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ipController,
            label: 'PC IP Address',
            hint: '192.168.1.1',
            prefixIcon: Icons.router,
            onChanged: (value) => serverIP = value,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: testConnection,
              isLoading: isConnecting,
              text: isConnected ? 'Reconnect' : 'Connect',
              icon: isConnected ? Icons.refresh : Icons.link,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityCard(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sensitivity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sensitivity.toStringAsFixed(1),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: sensitivity,
              min: 0.1,
              max: 3.0,
              divisions: 29,
              onChanged: (value) {
                setState(() {
                  sensitivity = value;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpadCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TouchpadArea(
          isConnected: isConnected,
          onPanUpdate: (details) {
            if (isConnected) {
              sendMouseCommand(
                'move',
                data: {
                  'dx': details.delta.dx * sensitivity,
                  'dy': details.delta.dy * sensitivity,
                },
              );
            }
          },
          onTap: () {
            if (isConnected) {
              sendMouseCommand('left_click');
              HapticFeedback.lightImpact();
            }
          },
        ),
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ControlButton(
                  icon: Icons.mouse,
                  label: 'Left Click',
                  onPressed: isConnected
                      ? () => sendMouseCommand('left_click')
                      : null,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ControlButton(
                  icon: Icons.menu,
                  label: 'Right Click',
                  onPressed: isConnected
                      ? () => sendMouseCommand('right_click')
                      : null,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ControlButton(
                  icon: Icons.keyboard_arrow_up,
                  label: 'Scroll Up',
                  onPressed: isConnected
                      ? () => sendMouseCommand('scroll_up')
                      : null,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ControlButton(
                  icon: Icons.keyboard_arrow_down,
                  label: 'Scroll Down',
                  onPressed: isConnected
                      ? () => sendMouseCommand('scroll_down')
                      : null,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
