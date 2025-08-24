// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(Mouser());
}

class Mouser extends StatelessWidget {
  const Mouser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Mouse Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MouserScreen(),
    );
  }
}

class MouserScreen extends StatefulWidget {
  const MouserScreen({super.key});

  @override
  _MouserScreenState createState() => _MouserScreenState();
}

class _MouserScreenState extends State<MouserScreen> {
  final TextEditingController _ipController = TextEditingController();
  String serverIP = '192.168.1.100'; // Default IP
  int serverPort = 8080;
  bool isConnected = false;
  double sensitivity = 1.0;

  @override
  void initState() {
    super.initState();
    _ipController.text = serverIP;
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
          .timeout(Duration(milliseconds: 500));

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
      }
    }
  }

  Future<void> testConnection() async {
    try {
      setState(() {
        serverIP = _ipController.text.trim();
      });

      final client = http.Client();
      debugPrint('Attempting to connect to: http://$serverIP:$serverPort/ping');

      final response = await client
          .get(
            Uri.parse('http://$serverIP:$serverPort/ping'),
            headers: {'Accept': 'application/json', 'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      client.close();

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to PC successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      setState(() {
        isConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PC Mouse Controller'),
        foregroundColor: Colors.white,
        backgroundColor: isConnected ? Colors.blue : Colors.red,
      ),
      body: Column(
        children: [
          // Connection Panel
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'PC IP Address',
                    hintText: '192.168.1.100',
                  ),
                  onChanged: (value) {
                    serverIP = value;
                  },
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: testConnection,
                  child: Text(isConnected ? 'Reconnect' : 'Connect'),
                ),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Sensitivity Control
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Sensitivity:'),
                Expanded(
                  child: Slider(
                    value: sensitivity,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    label: sensitivity.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        sensitivity = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Touchpad Area
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: GestureDetector(
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
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 64,
                          color: Colors.blue.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Touchpad',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Move: Drag to move cursor\nTap: Left click',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Button Controls
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isConnected
                      ? () => sendMouseCommand('left_click')
                      : null,
                  child: Text('Left Click'),
                ),
                ElevatedButton(
                  onPressed: isConnected
                      ? () => sendMouseCommand('right_click')
                      : null,
                  child: Text('Right Click'),
                ),
                ElevatedButton(
                  onPressed: isConnected
                      ? () => sendMouseCommand('scroll_up')
                      : null,
                  child: Text('Scroll Up'),
                ),
                ElevatedButton(
                  onPressed: isConnected
                      ? () => sendMouseCommand('scroll_down')
                      : null,
                  child: Text('Scroll Down'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
