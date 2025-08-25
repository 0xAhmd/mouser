# 📱💻 Remote Mouse & Keyboard Controller

A Flutter mobile application that transforms your phone into a wireless mouse and keyboard for your PC/laptop. Control your computer remotely over WiFi with intuitive touch gestures and virtual keyboard input.

## ✨ Features

### 🖱️ Mouse Control
- **Touchpad Navigation**: Use your phone screen as a trackpad
- **Click Actions**: Left click, right click, double click
- **Scrolling**: Vertical scrolling with finger gestures
- **Drag & Drop**: Touch and drag functionality

### ⌨️ Keyboard Control
- **Text Input**: Type text using virtual keyboard
- **Special Keys**: Enter, Backspace, Delete, Tab, Escape, etc.
- **Arrow Keys**: Navigation keys (Up, Down, Left, Right)
- **Function Keys**: F1-F12 support
- **Key Combinations**: Ctrl+C, Ctrl+V, Alt+Tab, etc.
- **Modifier Keys**: Shift, Ctrl, Alt, Cmd support

## 🏗️ Architecture

The project follows Clean Architecture principles with clear separation of concerns:

```
flutter_app/
├── lib/
│   ├── features/
│   │   ├── mouse_feat/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── repositories/
│   │   │   │   └── services/
│   │   │   └── presentation/
│   │   │       ├── cubit/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   │   └── keyboard_feat/
│   │       ├── data/
│   │       │   ├── models/
│   │       │   ├── repositories/
│   │       │   └── services/
│   │       └── presentation/
│   │           ├── cubit/
│   │           ├── pages/
│   │           └── widgets/
│   ├── core/
│   │   ├── network/
│   │   └── utils/
│   └── main.dart
└── server-side/
    └── mouse_keyboard_server.py
```

## 🛠️ Tech Stack

### Flutter App
- **State Management**: Cubit (Bloc pattern)
- **Networking**: Retrofit with JSON Serializable
- **Responsive Design**: Flutter ScreenUtil
- **HTTP Client**: Dio
- **Code Generation**: build_runner, json_annotation

### Server
- **Language**: Python 3
- **Framework**: Flask
- **Input Control**: pynput
- **Network**: Socket programming

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Python 3.7+
- PC/Laptop running Ubuntu/Linux (or Windows/macOS with minor modifications)

### Server Setup

1. **Install Python dependencies**:
```bash
pip install flask pynput
```

2. **Run the server**:
```bash
cd server-side
python3 mouse_keyboard_server.py
```

3. **Note the server IP** displayed in the console output.

### Flutter App Setup

1. **Clone and setup**:
```bash
flutter pub get
flutter pub run build_runner build
```

2. **Run the app**:
```bash
flutter run
```

3. **Connect to server**:
   - Enter the server IP shown in the Python console
   - Tap "Connect"
   - Start controlling your PC!

## 📡 API Endpoints

### Mouse Control
```http
POST /mouse
Content-Type: application/json

{
  "action": "move|left_click|right_click|double_click|scroll_up|scroll_down|drag_start|drag_end",
  "data": {
    "dx": 10,    // For move action
    "dy": 5      // For move action
  }
}
```

### Keyboard Control
```http
POST /keyboard
Content-Type: application/json

{
  "action": "type|key_press|key_combination|key_hold_start|key_hold_end",
  "data": {
    "text": "Hello World",           // For type action
    "key": "enter",                // For key_press action
    "keys": ["ctrl", "c"]          // For key_combination action
  }
}
```

### Status & Health Check
```http
GET /status    # Get server status and mouse position
GET /ping      # Health check
```

## 🎯 Usage Examples

### Basic Mouse Operations
```dart
// Move mouse
await mouseService.sendCommand('move', {'dx': 50, 'dy': 30});

// Left click
await mouseService.sendCommand('left_click', {});

// Scroll up
await mouseService.sendCommand('scroll_up', {});
```

### Keyboard Operations
```dart
// Type text
await keyboardService.sendCommand('type', {'text': 'Hello World'});

// Press Enter key
await keyboardService.sendCommand('key_press', {'key': 'enter'});

// Copy shortcut (Ctrl+C)
await keyboardService.sendCommand('key_combination', {'keys': ['ctrl', 'c']});
```

## 🔧 Configuration

### Network Configuration
- Ensure both devices are on the same WiFi network
- Default server port: 8080
- Server accepts connections from any IP (0.0.0.0)

### Customization Options
- Adjust mouse sensitivity in Flutter app settings
- Modify server port in Python script if needed
- Add custom key mappings in the server code

## 🐛 Troubleshooting

### Common Issues

**Connection Failed**
- Verify both devices are on the same WiFi
- Check if the server IP is correct
- Ensure port 8080 is not blocked by firewall

**Mouse/Keyboard Not Responding**
- Restart the Python server
- Check server console for error messages
- Verify pynput permissions on your system

**Performance Issues**
- Reduce mouse sensitivity
- Check network latency
- Close unnecessary applications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🎉 Acknowledgments

- **pynput** library for cross-platform input control
- **Flutter** team for the amazing mobile framework
- **Flask** for the lightweight web framework

## 📞 Support

If you encounter any issues or have questions:
1. Check the troubleshooting section above
2. Open an issue on GitHub
3. Review the API documentation

---

**Made with ❤️ using Flutter and Python**